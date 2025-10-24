# Mikrotik SwOS (Lite) 设备模型
# 支持 Mikrotik SwOS (Lite) 网络设备的配置备份
class SwOS < Oxidized::Model
  using Refinements

  # 获取备份文件
  cmd '/backup.swb'
  
  # HTTP 连接配置
  cfg :http do
    # 设置用户名
    @username = @node.auth[:username]
    # 设置密码
    @password = @node.auth[:password]
    # 禁用安全连接
    @secure = false
  end
end
