# Hirschmann 设备模型
# 支持 Hirschmann 网络设备的配置备份
class Hirschmann < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 Hirschmann 设备提示符
  prompt /^[(\w\s)]+\s[>|#]+?$/
  # 注释字符：Hirschmann 使用双井号作为注释
  comment '## '

  # 处理分页显示
  # Handle pager
  expect /^--More--.*$/ do |data, re|
    send 'a'
    data.sub re, ''
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理系统信息，移除动态信息
  cmd 'show sysinfo' do |cfg|
    cfg.gsub! /^System Up Time.*\n/, ""
    cfg.gsub! /^System Date and Time.*\n/, ""
    cfg.gsub! /^CPU Utilization.*\n/, ""
    cfg.gsub! /^Memory.*\n/, ""
    cfg.gsub! /^Average CPU Utilization.*\n/, ""
    comment cfg
  end

  # 处理运行配置，移除用户信息
  cmd 'show running-config' do |cfg|
    cfg.gsub! /^users.*\n/, ""
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^User:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login 'enable'
    pre_logout 'logout'
  end
end
