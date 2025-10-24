# Voltaire 设备模型
# 支持 Voltaire 网络设备的配置备份
class VOLTAIRE < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 Voltaire 设备提示符
  prompt /([\w.@()-\[:\s\]]+[#>]\s|(One or more tests have failed.*))$/
  # 注释字符：Voltaire 使用双井号作为注释
  comment '## '

  # 处理分页显示
  # Pager Handling
  expect /.+lines\s\d+-\d+(\s|\/\d+\s\(END\)\s).+$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 处理所有命令的输出，清理分页器和动态信息
  cmd :all do |cfg|
    cfg.gsub! /\[\?1h=\r/, '' # Pager Handling
    cfg.gsub! /\r\[K/, '' # Pager Handling
    cfg.gsub! /\s/, '' # Linebreak Handling
    cfg.gsub! /^CPU load averages:\s.+/, '' # Omit constantly changing CPU info
    cfg.gsub! /^System memory:\s.+/, '' # Omit constantly changing memory info
    cfg.gsub! /^Uptime:\s.+/, '' # Omit constantly changing uptime info
    cfg.gsub! /.+Generated at\s\d+.+/, '' # Omit constantly changing generation time info
    cfg.lines.to_a[2..-3].join
  end

  # 处理敏感信息，隐藏 SNMP 社区字符串和用户密码
  cmd :secret do |cfg|
    cfg.gsub! /(snmp-server community).*/, '   <snmp-server community configuration removed>'
    cfg.gsub! /username (\S+) password (\d+) (\S+).*/, '<secret hidden>'
    cfg
  end

  # 处理版本信息
  cmd 'version show' do |cfg|
    comment cfg
  end

  # 处理固件版本信息
  cmd 'firmware-version show' do |cfg|
    comment cfg
  end

  # 处理远程信息
  cmd 'remote show' do |cfg|
    cfg
  end

  # 处理系统管理信息
  cmd 'sm-info show' do |cfg|
    cfg
  end

  # 处理配置信息
  cmd ' show' do |cfg|
    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    post_login "no\n"
    password /^Password:\s*/
    pre_logout 'exit'
  end
end