# D-Link 下一代设备模型
# 支持 D-Link 下一代 CLI 交换机
# 添加对 DXS-1210-12SC 的支持
class DlinkNextGen < Oxidized::Model
  using Refinements

  # D-LINK next generation cli Switches
  # Add support DXS-1210-12SC

  # 提示符正则表达式：匹配 D-Link 下一代设备提示符
  prompt /[\w.@()\/-]+[#>]\s?$/
  # 注释字符：D-Link 下一代使用井号作为注释
  comment '# '

  # 处理所有命令的输出，清理回车符和空白字符
  cmd :all do |cfg|
    cfg.each_line.to_a[2..-2].map { |line| line.delete("\r").rstrip }.join("\n") + "\n"
  end

  # 处理敏感信息，隐藏密码和 SNMP 信息
  cmd :secret do |cfg|
    cfg.gsub! /(password) (\S+).*/, '\\1 <secret hidden>'
    cfg.gsub! /(snmp-server group) (\S+) (v.*)/, '\\1 <secret hidden> \\3'
    cfg.gsub! /(snmp-server community) (\S+) (v.*)/, '\\1 <secret hidden> \\3'
    cfg
  end

  # 处理交换机信息（某些型号不支持此命令）
  # "show switch" doesn't exist on DXS-1210-28T rev A1 Firmware: Build 1.00.024; not figured out how to run "show version" so running both
  cmd 'show switch' do |cfg|
    cfg.gsub! /^\s+System Time\s.+/, '' # Omit constantly changing uptime info
    comment cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理 VLAN 信息
  cmd 'show vlan' do |cfg|
    comment cfg
  end

  # 处理运行配置，清理敏感信息和动态信息
  cmd 'show running-config' do |cfg|
    cfg.gsub! /^(snmp-server community ["\w]+) \S+/, '\\1 <removed>'
    cfg.gsub! /^(username [\w.@-]+ privilege \d{1,2} password \d{1,2}) \S+/, '\\1 <removed>'
    cfg.gsub! /^(!System Up Time).*/, '\\1 <removed>'
    cfg.gsub! /^(!Current SNTP Synchronized Time:).*/, '\\1 <removed>'
    cfg.gsub! /^(\s+ppp (chap|pap) password \d) .+/, '\\1 <secret hidden>'
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /\r*([\w\s.@()\/:-]+)?([Uu]ser[Nn]ame|[Ll]ogin):/
    password /\r*[Pp]ass[Ww]ord:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    post_login 'terminal width 255'
    pre_logout 'logout'
  end
end
