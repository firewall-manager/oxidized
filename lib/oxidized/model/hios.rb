# Hios 设备模型
# 支持 Hios 网络设备的配置备份
class Hios < Oxidized::Model
  using Refinements

  ## Docker location: /var/lib/gems/2.7.0/gems/oxidized-0.28.0/lib/oxidized/model/hios.rb
  # 提示符正则表达式：匹配 Hios 设备提示符
  prompt /^\[[\w\s\W]+\][>|#]+?$/
  # 注释字符：Hios 使用双井号作为注释
  comment '## '

  # 处理分页显示
  # Handle pager
  expect /^--More--.*$/ do |data, re|
    send 'n'
    data.sub re, ''
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理系统信息，移除动态信息
  cmd 'show system info' do |cfg|
    cfg.gsub! /^System uptime.*\n/, ""
    cfg.gsub! /^Operating hours.*\n/, ""
    cfg.gsub! /^System date.*\n/, ""
    cfg.gsub! /^Current temperature.*\n/, ""
    comment cfg
  end

  # 处理运行配置脚本
  cmd 'show running-config script' do |cfg|
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
    pre_logout "logout\nY\r\n"
  end
end
