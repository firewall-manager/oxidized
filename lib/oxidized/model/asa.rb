# Cisco ASA 设备模型
# 支持 Cisco ASA (Adaptive Security Appliance) 防火墙的配置备份
# 仅支持 SSH 连接以确保安全性
class ASA < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 ASA 设备提示符
  prompt /^\r*([\w.@()-\/]+[#>]\s?)$/
  # 注释字符：ASA 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏启用密码
    cfg.gsub! /enable password (\S+) (.*)/, 'enable password <secret hidden> \2'
    # 隐藏密码
    cfg.gsub! /^passwd (\S+) (.*)/, 'passwd <secret hidden> \2'
    # 隐藏用户名密码
    cfg.gsub! /username (\S+) password (\S+) (.*)/, 'username \1 password <secret hidden> \3'
    # 隐藏 IKE 预共享密钥
    cfg.gsub! /(ikev[12] ((remote|local)-authentication )?pre-shared-key( hex)?) (\S+)/, '\1 <secret hidden>'
    # 隐藏 AAA 服务器密钥
    cfg.gsub! /^(aaa-server \S+(?: \(\S+\))? host \S+\n(?: [^\n]+\n)* +key) \S+$/mi, '\1 <secret hidden>'
    # 隐藏 LDAP 登录密码
    cfg.gsub! /ldap-login-password (\S+)/, 'ldap-login-password <secret hidden>'
    # 隐藏 SNMP 服务器社区字符串
    cfg.gsub! /^snmp-server host (.*) community (\S+)/, 'snmp-server host \1 community <secret hidden>'
    # 隐藏故障转移密钥
    cfg.gsub! /^(failover key) .+/, '\1 <secret hidden>'
    # 隐藏 OSPF 消息摘要密钥
    cfg.gsub! /^(\s+ospf message-digest-key \d+ md5) .+/, '\1 <secret hidden>'
    # 隐藏 OSPF 认证密钥
    cfg.gsub! /^(\s+ospf authentication-key) .+/, '\1 <secret hidden>'
    # 隐藏邻居密码
    cfg.gsub! /^(\s+neighbor \S+ password) .+/, '\1 <secret hidden>'
    cfg
  end

  # 检查多上下文模式
  cmd 'show mode' do |cfg|
    @is_multiple_context = cfg.include? 'multiple'
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    # 避免因运行时间导致的提交 / ixo-router01 up 2 mins 28 secs / ixo-router01 up 1 days 2 hours
    cfg = cfg.each_line.reject { |line| line.match /(\s+up\s+\d+\s+)|(.*days.*)/ }
    cfg = cfg.join
    # 移除配置修改信息
    cfg.gsub! /^Configuration has not been modified since last system restart.*\n/, ''
    cfg.gsub! /^Configuration last modified by.*\n/, ''
    cfg.gsub! /^Start-up time.*\n/, ''
    comment cfg
  end

  # 处理库存信息
  cmd 'show inventory' do |cfg|
    comment cfg
  end

  # 后处理：根据上下文模式选择处理方式
  post do
    if @is_multiple_context
      multiple_context
    else
      single_context
    end
  end

  # SSH 连接配置
  cfg :ssh do
    if vars :enable
      post_login do
        # 启用特权模式
        send "enable\n"
        cmd vars(:enable)
      end
    end
    # 设置终端分页器
    post_login 'terminal pager 0'
    # 退出命令
    pre_logout 'exit'
  end

  # 单上下文模式处理
  def single_context
    cmd 'more system:running-config' do |cfg|
      # 移除前3行
      cfg = cfg.each_line.to_a[3..-1].join
      # 移除冒号开头的行
      cfg.gsub! /^: [^\n]*\n/, ''
      # 备份配置中引用的任何 XML 文件
      anyconnect_profiles = cfg.scan(Regexp.new('(\sdisk0:/.+\.xml)')).flatten
      anyconnect_profiles.each do |profile|
        cfg << (comment profile + "\n")
        cmd("more" + profile) do |xml|
          cfg << (comment xml)
        end
      end
      # 如果启用了 DAP，也备份 dap.xml
      if cfg.rindex(/dynamic-access-policy-record\s(?!DfltAccessPolicy)/)
        cfg << (comment "disk0:/dap.xml\n")
        cmd "more disk0:/dap.xml" do |xml|
          cfg << (comment xml)
        end
      end
      cfg
    end
  end

  # 多上下文模式处理
  def multiple_context
    cmd 'changeto system' do |cfg|
      cmd 'show running-config' do |systemcfg|
        allcfg = "\n\n" + systemcfg + "\n\n"
        # 提取上下文和文件信息
        contexts = systemcfg.scan(/^context (\S+)$/)
        files = systemcfg.scan(/config-url (\S+)$/)
        # 处理每个上下文
        contexts.each_with_index do |cont, i|
          allcfg = allcfg + "\n\n----------========== [ CONTEXT " + cont.join(" ") +
                   " FILE " + files[i].join(" ") + " ] ==========----------\n\n"
          cmd "more " + files[i].join(" ") do |cfgcontext|
            allcfg = allcfg + "\n\n" + cfgcontext
          end
        end
        cfg = allcfg
      end
      cfg
    end
  end
end
