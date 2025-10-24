# AEN 设备模型
# 支持 Accedian 设备的配置备份
class AEN < Oxidized::Model
  using Refinements

  # Accedian

  # 注释字符：AEN 使用井号作为注释
  comment '# '

  # 提示符正则表达式：匹配 AEN 设备提示符
  prompt /^([-\w.\/:?\[\]()]+:\s?)$/

  # 生成所有模块的配置脚本
  cmd 'configuration generate-script module all' do |cfg|
    cfg
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # SSH 连接配置
  cfg :ssh do
    pre_logout 'exit'
  end
end
