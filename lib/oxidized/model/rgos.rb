# RGOS 设备模型
# 支持 RGOS 网络设备的配置备份
class RGOS < Oxidized::Model
  using Refinements

  # 注释字符：RGOS 使用感叹号作为注释
  comment '! '

  # 处理敏感信息，隐藏 SNMP 社区字符串、用户名密码和启用密码
  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(username .+ (password|secret) \d) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(enable (password|secret)( level \d+)?( \d)?) .+/, '\\1 <secret hidden>'
    cfg
  end

  # 处理版本信息，移除系统启动时间和运行时间信息
  cmd 'show version' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match /^System start time/ }.join
    cfg = cfg.each_line.reject { |line| line.match /^\s*System uptime/ }.join
    comment "#{cfg.cut_both}\n"
  end

  # 处理运行配置，清理构建信息和版本信息
  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match /^Building configuration.../ }.join
    cfg = cfg.each_line.reject { |line| line.match /^Current configuration : \d+ bytes/ }.join
    cfg = cfg.each_line.reject { |line| line.match /^version [\d\w()]+/ }.join
    # remove empty lines
    cfg = cfg.each_line.reject { |line| line.match /^[\r\n\s\u0000#]+$/ }.join
    cfg.cut_both
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    pre_logout 'exit'
  end
end
