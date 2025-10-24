# FiberDriver 设备模型
# 支持 FiberDriver 网络设备的配置备份
class FiberDriver < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 FiberDriver 设备提示符
  prompt /\w+#/
  # 注释字符：FiberDriver 使用感叹号作为注释
  comment "! "

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end
  
  # 处理库存信息
  cmd 'show inventory' do |cfg|
    comment cfg
  end

  # 处理运行配置，清理构建信息
  cmd "show running-config" do |cfg|
    cfg.each_line.to_a[3..-1].join
    cfg.gsub! /^Building configuration.*$/, ''
    cfg.gsub! /^Current configuration:.*$$/, ''
    cfg.gsub! /^! Configuration (saved|generated) on .*$/, ''
    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    post_login 'terminal length 0'
    post_login 'terminal width 512'
    pre_logout 'exit'
  end
end
