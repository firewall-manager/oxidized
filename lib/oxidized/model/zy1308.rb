# Zyxel OLT 1308 设备模型
# 支持 Zyxel OLT 1308 系列设备的配置备份
# For Zyxel OLTs series 1308
class Zy1308 < Oxidized::Model
  using Refinements

  # For Zyxel OLTs series 1308

  # 获取配置文件
  cmd '/config_OLT-1308S-22.log'
  
  # HTTP 连接配置
  cfg :http do
    @username = @node.auth[:username]
    @password = @node.auth[:password]
    @secure = false
  end
end
