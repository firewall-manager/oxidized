# Brocade NOS 设备模型
# 支持 Brocade Network Operating System 的配置备份
class NOS < Oxidized::Model
  using Refinements

  # Brocade Network Operating System

  # 提示符正则表达式：匹配 Brocade NOS 设备提示符
  prompt /^(?:\e\[..h)?[\w.-]+# $/
  # 注释字符：Brocade NOS 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理版本信息，移除系统运行时间
  cmd 'show version' do |cfg|
    comment cfg.each_line.reject { |line| line.match /([Ss]ystem [Uu]p\s?[Tt]ime|[Uu]p\s?[Tt]ime is \d)/ }.join
  end

  # 处理设备清单信息
  cmd 'show inventory' do |cfg|
    comment cfg
  end

  # 处理许可证信息
  cmd 'show license' do |cfg|
    comment cfg
  end

  # 处理机箱信息，移除时间和更新信息
  cmd 'show chassis' do |cfg|
    comment cfg.each_line.reject { |line| line.match(/Time/) || line.match(/Update/) }.join
  end

  # 处理系统信息，移除时间和速度信息
  cfg 'show system' do |cfg|
    comment(cfg.each_line.reject { |line| line.match(/Time/) || line.match(/speed/) })
  end

  # 处理运行配置，禁用分页器
  cmd 'show running-config | nomore'

  # Telnet 连接配置
  cfg :telnet do
    username /^.* login: /
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    # post_login 'terminal width 0'
    pre_logout 'exit'
  end
end
