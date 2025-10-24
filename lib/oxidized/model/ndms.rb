# Zyxel NDMS 设备模型
# 支持 Zyxel Keenetic 设备的配置备份
# 从 NDMS >= 2.0 版本中拉取配置
class NDMS < Oxidized::Model
  using Refinements

  # Pull config from Zyxel Keenetic devices from version NDMS >= 2.0

  # 注释字符：NDMS 使用感叹号作为注释
  comment '! '

  # 提示符正则表达式：匹配 NDMS 设备提示符
  prompt /^([\w.@()-]+[#>]\s?)/m

  # 处理版本信息
  cmd 'show version' do |cfg|
    cfg = cfg.each_line.to_a[1..-3].join
    comment cfg
  end

  # 处理运行配置，移除时钟和校验和信息
  cmd 'show running-config' do |cfg|
    cfg = cfg.cut_both.each_line.reject { |line| line.match /(clock date|checksum)/ }.join
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Login:/
    password /^Password:/
    pre_logout 'exit'
  end
end
