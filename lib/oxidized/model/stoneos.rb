# Hillstone Networks StoneOS 设备模型
# 支持 Hillstone Networks StoneOS 软件的配置备份
class StoneOS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 StoneOS 设备提示符
  prompt /^\r?[\w.()-]+~?[#>](\s)?$/
  # 注释字符：StoneOS 使用井号作为注释
  comment '# '

  # 处理分页器
  expect /^\s.*--More--.*$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg.gsub! /+.*+/, '' # Linebreak handling
    cfg.cut_both
  end

  cmd 'show configuration running' do |cfg|
    cfg.gsub! /^Building configuration.*$/, ''
  end

  cmd 'show version' do |cfg|
    cfg.gsub! /^Uptime is .*$/, ''
    comment cfg
  end

  cfg :telnet do
    username(/^login:/)
    password(/^Password:/)
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 256'
    post_login 'terminal width 512'
    pre_logout 'exit'
  end
end
