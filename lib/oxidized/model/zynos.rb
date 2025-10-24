# ZynOS 设备模型
# 支持 Zyxel ZynOS 网络设备的配置备份
# 用于 Zyxel DSLAM，如 SAM1316
class ZyNOS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 ZynOS 设备提示符
  prompt /^([\w.@()\-<]+[#>]\s?)$/
  # if there is something you can not identify after prompt, uncomment next line and comment previous line
  # prompt /^([\w.@()\-<]+[#>]\s?).*$/

  # 注释字符：ZynOS 使用感叹号作为注释
  comment '! '

  # Used in Zyxel DSLAMs, such as SAM1316. Uncomment next line to enable ftp.
  # cmd 'config-0'

  # 将下一行控制序列替换为换行符
  # replace next line control sequence with a new line
  expect /(\e\[1M\e\[\??\d+(;\d+)*[A-Za-z]\e\[1L)|(\eE)/ do |data, re|
    data.gsub re, "\n"
  end

  # 替换所有使用的 vt100 控制序列
  # replace all used vt100 control sequences
  expect /\e\[\??\d+(;\d+)*[A-Za-z]/ do |data, re|
    data.gsub re, ''
  end

  # 忽略版权信息
  # ignore copyright motd
  expect /^(Copyright .*)\n^([\w.@()\-<]+[#>]\s?)$/ do
    send '\n'
    ""
  end

  # 处理所有命令的输出，清理控制字符
  cmd :all do |cfg|
    cfg = cfg.gsub /^\r/, ''
    # Additional filtering for elder switches sending vt100 control chars via telnet
    cfg.gsub! /\e\[\??\d+(;\d+)*[A-Za-z]/, ''
    cfg
  end

  # 处理敏感信息，隐藏 SNMP 社区字符串、用户名、密码和管理员密码
  # remove snmp community, username, password and admin-password
  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server get-community) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(snmp-server set-community) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(logins username) \S+(.*) (password) \S+(.*)/, '\\1 <secret hidden> \\2 \\3 <secret hidden> \\4'
    cfg.gsub! /^(admin-password) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(password) \S+(.*) (privilege \S+)/, '\\1 <secret hidden> \\2 \\3'
    cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理系统信息，移除运行时间
  cmd 'show system-information' do |cfg|
    cfg.gsub! /^([Ss]ystem up [Tt]ime\s*:)(.*)/, '\\1 <time removed>'
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg = cfg.split("\n")[4..-2].join("\n")
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^User name:/i
    password /^Password:/i
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    pre_logout 'exit'
  end
end
