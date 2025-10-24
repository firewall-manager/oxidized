# Alvarion 设备模型
# 支持 Alvarion WISP 设备的配置备份
class Alvarion < Oxidized::Model
  using Refinements

  # Used in Alvarion wisp equipment

  # 预处理：作为 Model 实例运行此命令，以便访问节点
  # Run this command as an instance of Model so we can access node
  pre do
    cmd "#{node.auth[:password]}.cfg"
  end

  # TFTP 连接配置
  cfg :tftp do
  end
end
