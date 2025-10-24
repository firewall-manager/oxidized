# Firebrick 设备模型
# 支持 Firebrick 路由器的配置备份
class Firebrick < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 Firebrick 设备提示符
  prompt /\x0a\x1b\x5b\x32\x4b\x0d.*>\s/

  # 处理所有命令的输出
  cmd :all do |cfg|
    # 移除命令后的任意空白字符
    cfg.each_line.to_a[1..-2].drop_while { |e| e.match /^\s+$/ }.join
  end

  # 处理状态信息
  cmd 'show status' do |cfg|
    # 移除状态标题
    cfg.gsub! "Status", ''
    cfg.gsub! "------", ''
    # 移除时间相关信息
    cfg.gsub! /Uptime.*/, ''
    cfg.gsub! /Current time.*/, ''
    # 移除硬件信息
    cfg.gsub! /RAM.*/, ''
    cfg.gsub! /Warranty.*/, ''

    comment cfg
  end

  # 处理配置信息
  cmd 'show configuration'

  # Telnet 连接配置
  cfg :telnet do
    username /Username:\s?/
    password /Password:\s?/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 退出命令
    pre_logout 'exit'
  end
end
