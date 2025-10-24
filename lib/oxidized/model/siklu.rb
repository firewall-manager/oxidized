# Siklu 设备模型
# 支持 Siklu EtherHaul 网络设备的配置备份
class Siklu < Oxidized::Model
  using Refinements

  # Siklu EtherHaul #

  # 提示符正则表达式：匹配 Siklu 设备提示符
  prompt /^[\^M\s]{0,}[\w\-\s."]+>$/

  # 处理启动配置显示
  cmd 'copy startup-configuration display' do |cfg|
    cfg.each_line.to_a[2..2].join
  end

  # 处理运行配置显示
  cmd 'copy running-configuration display' do |cfg|
    cfg.each_line.to_a[3..-2].join
  end

  # SSH 连接配置
  cfg :ssh do
    pre_logout 'exit'
  end
end
