# Casa Systems 设备模型
# 支持 Casa Systems CMTS 的配置备份
class Casa < Oxidized::Model
  using Refinements

  # Casa Systems CMTS

  # 提示符正则表达式：匹配 Casa Systems 设备提示符
  prompt /^([\w.@()-]+[#>]\s?)$/
  # 注释字符：Casa Systems 使用感叹号作为注释
  comment '! '

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    cfg.gsub! /^(snmp community) \S+/, '\\1 <configuration removed>'
    cfg.gsub! /^(snmp comm-tbl) \S+ \S+/, '\\1 <removed> <removed>'
    cfg.gsub! /^(console-password encrypted) \S+/, '\\1 <secret hidden>'
    cfg.gsub! /^(password encrypted) \S+/, '\\1 <secret hidden>'
    cfg.gsub! /^(tacacs-server key) \S+/, '\\1 <secret hidden>'
    cfg.gsub! /^(  ip rip authentication secret) \S+/, '\\1 <secret hidden>'
    cfg
  end

  # 处理所有命令的输出，移除首尾行
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理系统信息，移除运行时间和时间信息
  cmd 'show system' do |cfg|
    cfg.gsub! /Uptime:.*/, 'Uptime: <removed>'
    cfg.gsub! /Time:.*/, 'Time: <removed>'
    comment cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show run'

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login 'page-off'
    # preferred way to handle additional passwords
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    pre_logout 'logout'
  end
end
