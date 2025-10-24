# Linksys SRW 设备模型
# 支持 Linksys SRW 系列交换机的配置备份
class LinksysSRW < Oxidized::Model
  using Refinements

  # 注释字符：Linksys SRW 使用感叹号作为注释
  comment '! '

  # 提示符正则表达式：匹配 Linksys SRW 设备提示符
  prompt /^([\r\w.@-]+[#>]\s?)$/

  # 图形登录屏幕
  # Graphical login screen
  # Just login to get to Main Menu
  expect /Login Screen/ do
    logger.debug "#{self.class.name}: Login Screen"
    # This is to ensure the whole thing have rendered before we send stuff
    sleep 0.2
    send 0x18.chr # CAN Cancel
    send @node.auth[:username]
    send "\t"
    send @node.auth[:password]
    send "\r"
    ''
  end

  # 主菜单，转义到预 CLI shell
  # Main menu, escape into Pre-cli-shell
  expect /Switch Main Menu/ do
    logger.debug "#{self.class.name}: Switch menu"
    send 0x1a.chr # SUB Substitite ^z
    ''
  end

  # 预 CLI shell，启动类似 IOS 的 lcli
  # Pre-cli-shell, start lcli which is ios-ish
  expect />/ do
    logger.debug "#{self.class.name}: >"
    send "lcli\r"
    ''
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    # Remove \r from first response row
    cfg.gsub! /^\r/, ''
    cfg.cut_tail + "\n"
  end

  # 处理敏感信息，隐藏 SNMP 社区字符串和启用密码
  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(enable (password|secret)( level \d+)? \d) .+/, '\\1 <secret hidden>'
  end

  # 处理启动配置，修复换行问题
  cmd 'show startup-config' do |cfg|
    # Repair some linewraps which terminal datadump doesn't take care of
    # and there's no terminal width either.
    cfg.gsub! /(lldpPortConfigT)\n(LVsTxEnable)/, '\\1\\2'
    cfg.gsub! /(lldpPortConfigTL)\n(VsTxEnable)/, '\\1\\2'
    # And comment out the echo of the command
    "#{comment cfg.lines.first}#{cfg.cut_head}"
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理系统信息，移除运行时间
  cmd 'show system' do |cfg|
    cfg.gsub! /(System Up Time \(days,hour:min:sec\):\s+).*/, '\\1 <uptime removed>'
    comment cfg
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # Some pre-cli-shell just expects a username, who its going to log in.
    username /^User Name:/
    password /Password:/
    post_login 'terminal datadump'
    pre_logout 'exit'
    pre_logout 'logout'
  end
end
