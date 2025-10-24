# HP MSM 设备模型
# 支持 HP MSM 网络设备的配置备份
class HPMSM < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 HP MSM 设备提示符
  prompt /^CLI[>#] +$/
  # 注释字符：HP MSM 使用感叹号作为注释
  comment '! '

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

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg = cfg.cut_both
    cfg = cfg.gsub /^\r/, ''
    cfg
  end

  # 处理敏感信息，隐藏 SNMP、RADIUS、TACACS 相关密钥
  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(snmp-server host \S+) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(radius-server host \S+ key) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(radius-server key).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(tacacs-server host \S+ key) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(tacacs-server key).*/, '\\1 <secret hidden>'
    cfg
  end

  # 处理系统信息，提取关键信息
  cmd 'show system info' do |cfg|
    sysinfo = ''
    ram = cfg.match(/Total RAM:\s+(\S+)/)[1].to_i / 1024 / 1024
    sysinfo << "Memory: #{ram}M\n"

    serial = cfg.match(/Serial Number:\s+(\S+)/)[1]
    sysinfo << "Serial Number: #{serial}\n"

    firmware = cfg.match(/Firmware Version:\s+(\S+)/)[1]
    sysinfo << "Firmware: #{firmware}\n"

    comment sysinfo
  end

  # 处理 IP 信息
  cmd 'show ip' do |cfg|
    comment cfg
  end

  # 处理 IP 路由信息
  cmd 'show ip route' do |cfg|
    comment cfg
  end

  # 处理证书信息
  cmd 'show certificate' do |cfg|
    comment cfg
  end

  # 处理证书绑定信息
  cmd 'show certificate binding' do |cfg|
    comment cfg
  end

  # 处理卫星信息
  cmd 'show satellites' do |cfg|
    comment cfg
  end

  # 处理 Web 内容信息
  cmd 'show web content' do |cfg|
    comment cfg
  end

  # 处理所有配置，移除动态信息
  cmd 'show all config' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match /^running configuration:/ }.join
    # The who line contains SSH source port number, and the When line contains the timestamp of the run
    cfg = cfg.each_line.reject { |line| line.match /(^#\s+Who:)|(^#\s+When:)/ }.join
    # igmp proxy line keeps changing with weird characters every run, filter it out
    cfg = cfg.each_line.reject { |line| line.match /^[ \t]*igmp proxy (upstream|downstream)/ }.join
    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    post_login "enable"
    pre_logout "quit"
    pty_options(chars_wide: 1000)
  end
end
