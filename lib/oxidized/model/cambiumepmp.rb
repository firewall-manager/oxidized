# Cambium ePMP 设备模型
# 支持 Cambium ePMP 无线设备的配置备份
class CambiumePMP < Oxidized::Model
  using Refinements

  # Cambium ePMP Radios

  # 提示符正则表达式：匹配 Cambium ePMP 设备提示符
  prompt /.*>/

  # 处理所有命令的输出，移除首尾行
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 预处理：获取 JSON 格式的配置
  pre do
    cmd 'config show json'
  end

  # SSH 连接配置
  cfg :ssh do
    pre_logout 'exit'
  end
end
