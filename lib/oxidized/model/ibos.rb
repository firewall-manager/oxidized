# IBM IBOS 设备模型
# 支持 IBM IBOS (Intelligent Broadband Operating System) 的配置备份
# 用于 Waystream（原 PacketFront）路由器和交换机
class IBOS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 IBOS 设备提示符
  prompt /^([\w.@()-]+[#>]\s?)$/
  # 注释字符：IBOS 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出，移除第一行和最后一行
  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏 SNMP 通知社区字符串
    # snmp-group version 2c
    #  notify 10.1.1.1 community public trap
    cfg.gsub! /^ notify (\S+) community (\S+) (.*)/, ' notify \\1 community <hidden> \\3'

    # 隐藏 SNMP 社区字符串
    # snmp-group version 2c
    #  community public read-only view all
    cfg.gsub! /^ community (\S+) (.*)/, ' community <hidden> \\2'

    # 隐藏 RADIUS 服务器密钥
    # radius server 10.1.1.1 secret public
    cfg.gsub! /^radius server (\S+) secret (\S+)(.*)/, 'radius server \\1 secret <hidden> \\3'
    cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    # 隐藏运行时间信息
    cfg.gsub! /.*uptime is.*/, ''
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[0..-1].join
    # 移除易失性配置
    cfg.gsub! /.*!volatile.*/, ''
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^username:\s/
    password /^\r?password:\s/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 处理额外密码的首选方式
    post_login do
      if vars(:enable) == true
        # 启用特权模式（无需密码）
        cmd "enable"
      elsif vars(:enable)
        # 启用特权模式（需要密码）
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    # 设置终端无分页器
    post_login 'terminal no pager'
    # 设置终端宽度
    post_login 'terminal width 65535'
    # 退出命令
    pre_logout 'exit'
  end
end
