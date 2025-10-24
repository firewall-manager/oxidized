# VMware NSX 配置模型
# 支持 VMware NSX 边缘设备的配置备份
require 'net/http'
class NSXConfig < Oxidized::Model
  using Refinements

  # 处理边缘设备配置
  cmd "/api/4.0/edges/" do |cfg|
    # 解析边缘设备列表
    edges = JSON.parse(cfg.encode('UTF-8', { invalid: :replace, undef: :replace, replace: '?' }))["edgePage"]["data"]
    data = []
    # 遍历每个边缘设备
    edges.each do |edge|
      # 获取边缘设备配置
      firewall_config = cmd "/api/4.0/edges/#{edge['id']}"
      json_config = JSON.parse(firewall_config.encode('UTF-8', { invalid: :replace, undef: :replace, replace: '?' }))
      # 添加边缘设备信息
      json_config["edgeInfo"] = "#{edge['id']} #{edge['name']}"
      data.push(json_config)
    end
    # 生成格式化的 JSON 输出
    JSON.pretty_generate(data)
  end

  # HTTP 连接配置
  cfg :http do
    @username = @node.auth[:username]
    @password = @node.auth[:password]
    @headers['Content-Type'] = 'application/json'
    @headers['Accept'] = 'application/json'
    @secure = true
  end
end
