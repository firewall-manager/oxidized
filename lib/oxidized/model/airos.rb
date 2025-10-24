# Ubiquiti AirOS 设备模型
# 支持 Ubiquiti AirOS 5.x 系列设备的配置备份
class Airos < Oxidized::Model
  using Refinements

  # Ubiquiti AirOS circa 5.x

  # 提示符正则表达式：匹配 AirOS 设备提示符
  prompt /^[^#]+# /
  # 注释字符：AirOS 使用井号作为注释
  comment '# '

  # 处理主板信息
  cmd 'cat /etc/board.info' do |cfg|
    cfg.split("\n").map { |line| "# #{line}" }.join("\n") + "\n"
  end

  # 处理版本信息
  cmd 'cat /etc/version' do |cfg|
    comment "airos version: #{cfg}"
  end

  # 处理系统配置（排序后）
  cmd 'sort /tmp/system.cfg'

  # 处理敏感信息，隐藏用户密码和 SNMP 社区字符串
  cmd :secret do |cfg|
    cfg.gsub! /^(users\.\d+\.password|snmp\.community)=.+/, "# \\1=<hidden>"
    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    exec true
  end
end
