# LANCOM 设备模型
# 支持 LANCOM Systems GmbH 网络设备的配置备份
# 测试设备：LANCOM 1781EF+ 路由器，使用 Lancom OS 10.32.0176RU9 / 21.04.2020
class LANCOM < Oxidized::Model
  using Refinements

  # LANCOM Systems GmbH
  # tested on LANCOM 1781EF+ router using Lancom OS 10.32.0176RU9 / 21.04.2020
  # 注释字符：LANCOM 使用井号作为注释
  comment '# '

  # 提示符正则表达式：匹配 LANCOM 设备提示符
  prompt />\s?$/

  # 处理系统信息，移除时间信息
  cmd "sysinfo\r" do |cfg|
    cfg.gsub! /^TIME:.*\n/, ''
    comment cfg
  end

  # 处理脚本读取
  cmd "readscript\r"

  # Telnet 连接配置
  cfg :telnet do
    username  /login:\s/
    password  /^Password:\s/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    pre_logout "exit\r"
  end
end
