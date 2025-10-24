# Enterasys 设备模型
# 支持 Enterasys B3/C3 系列设备的配置备份
class Enterasys < Oxidized::Model
  using Refinements

  # Enterasys B3/C3 models #

  # 提示符正则表达式：匹配 Enterasys 设备提示符
  prompt /^.+\w\((su|rw)\)->\s?$/
  # 注释字符：Enterasys 使用感叹号作为注释
  comment '!'

  # 处理分页显示
  # Handle paging
  expect /^--More--.*$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.each_line.to_a[2..-3].map { |line| line.delete("\r").rstrip }.join("\n") + "\n"
  end

  # 处理系统硬件信息
  cmd 'show system hardware' do |cfg|
    comment cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理配置信息，清理默认配置提示
  cmd 'show config' do |cfg|
    cfg.gsub! /^This command shows non-default configurations only./, ''
    cfg.gsub! /^Use 'show config all' to show both default and non-default configurations./, ''
    cfg.gsub! /^!|#.*/, ''
    cfg.gsub! /^$\n/, ''

    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/i
    password /^Password:/i
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    pre_logout 'exit'
  end
end
