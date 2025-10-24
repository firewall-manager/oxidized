# Kornfeld OS 设备模型
# 支持运行 Kornfeld OS 的交换机配置备份
# 测试设备：Kornfeld D1156 和 Kornfeld D2132
class KornfeldOS < Oxidized::Model
  using Refinements

  # For switches running Kornfeld OS
  #
  # Tested with : Kornfeld D1156 and Kornfeld D2132

  # 注释字符：Kornfeld OS 使用井号作为注释
  comment  '# '

  # 处理所有命令的输出，移除错误标记
  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.each_line.to_a[2..-2].join
  end

  # 处理版本信息，排除仓库、Docker 和运行时间信息
  cmd 'show version | except REPOSITORY | except docker | except Uptime' do |cfg|
    comment cfg
  end

  # 处理平台固件信息
  cmd 'show platform firmware' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-configuration' do |cfg|
    cfg.each_line.to_a[0..-1].join
  end

  # SSH 连接配置
  cfg :ssh do
    username /^Login:/
    password /^Password:/
    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
