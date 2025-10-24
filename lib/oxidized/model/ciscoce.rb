# Cisco Catalyst Express 设备模型
# 支持 Cisco Catalyst Express 交换机和 IOS 使用基本 Web 接口的配置备份
class CiscoCE < Oxidized::Model
  using Refinements

  # 处理启动配置
  cmd "/level/15/exec/-/show/startup-config" do |cfg|
    # 从 HTML 响应中提取配置文件
    output = cfg.gsub(/\A.+<DL>(.+)<\/DL>.+\z/m, '\1')
    output
  end

  # HTTP 连接配置
  cfg :http do
    @username = @node.auth[:username]
    @password = @node.auth[:password]
  end
end
