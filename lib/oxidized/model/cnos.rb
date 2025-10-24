# Centec Networks CNOS 设备模型
# 支持基于 Centec Networks CNOS 的交换机配置备份
# model for Centec Networks CNOS based switches
class CNOS < Oxidized::Model
  using Refinements

  # 注释字符：CNOS 使用感叹号作为注释
  comment '! '

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(username .+ (password|secret) \d) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(enable (password|secret)( level \d+)?( \d)?) .+/, '\\1 <secret hidden>'
    cfg
  end

  # 处理所有命令的输出，清理回车符
  cmd :all do |cfg|
    cfg = cfg.delete("\r")
    cfg.cut_both
  end

  # 处理版本信息，移除运行时间信息
  cmd 'show version' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match /\ uptime\ is\ / }.join
    comment cfg
  end

  # 处理收发器信息
  cmd 'show transceiver' do |cfg|
    comment cfg
  end

  # 处理运行配置，移除空行
  cmd 'show running-config' do |cfg|
    # remove empty lines
    cfg = cfg.each_line.reject { |line| line.match /^[\r\n\s\u0000#]+$/ }.join
    cfg
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
