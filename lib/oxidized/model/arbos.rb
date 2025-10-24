# Arbor OS 设备模型
# 支持 Arbor OS 网络设备的配置备份
class ARBOS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 Arbor OS 设备提示符
  prompt /^[\S\s]+\n([\w.@-]+[:\/#>]+)\s?$/
  # 注释字符：Arbor OS 使用井号作为注释
  comment '# '

  # 处理系统硬件信息
  cmd 'system hardware' do |cfg|
    # 移除启动时间信息
    cfg.gsub! /^Boot time:\s.+/, ''
    # 移除 CPU 负载信息
    cfg.gsub! /^Load averages:\s.+/, ''
    # 移除前两行
    cfg = cfg.each_line.to_a[2..-1].join
    comment cfg
  end

  # 处理系统版本信息
  cmd 'system version' do |cfg|
    comment cfg
  end

  # 处理配置显示
  cmd 'config show' do |cfg|
    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    exec true
    # 退出命令
    pre_logout 'exit'
  end
end
