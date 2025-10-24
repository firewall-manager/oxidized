# Ubiquiti Airfiber 设备模型
# 支持 Ubiquiti Airfiber 设备的配置备份（已测试 Airfiber 11FX）
class Airfiber < Oxidized::Model
  using Refinements

  # Ubiquiti Airfiber (tested with Airfiber 11FX)

  # 提示符正则表达式：匹配 Airfiber 设备提示符
  prompt /^AF[\w.-]+#/i

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 预处理：获取系统配置文件
  pre do
    cmd 'cat /tmp/system.cfg'
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^[\w\W]+\slogin:\s$/
    password /^[p:P]assword:\s$/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    pre_logout 'exit'
  end
end
