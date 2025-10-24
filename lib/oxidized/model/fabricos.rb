# Brocade Fabric OS 设备模型
# 支持 Brocade Fabric OS 网络设备的配置备份
class FabricOS < Oxidized::Model
  using Refinements

  # Brocade Fabric OS model #
  ## FIXME: Only ssh exec mode support, no telnet, no ssh screenscraping

  # 提示符正则表达式：匹配 Fabric OS 设备提示符
  prompt /^(\w+:+\w+>\s)$/
  # 注释字符：Fabric OS 使用井号作为注释
  comment '# '

  # 处理机箱信息，移除动态信息
  cmd 'chassisShow' do |cfg|
    comment cfg.each_line.reject { |line| line.match(/Time Awake:/) || line.match(/Power Usage \(Watts\):/) || line.match(/Power Usage:/) || line.match(/Time Alive:/) || line.match(/Update:/) || line.match(/PS Voltage input:/) }.join
  end

  # 处理配置显示，移除日期信息
  cmd 'configShow -all' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match /date = / }.join
    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    exec true # don't run shell, run each command in exec channel
  end
end
