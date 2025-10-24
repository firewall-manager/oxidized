# VMware NSX 防火墙模型
# 支持 VMware NSX 防火墙的配置备份
require 'net/http'
class NSXFirewall < Oxidized::Model
  using Refinements

  # 处理边缘防火墙配置
  cmd "/api/4.0/edges/" do |cfg|
    # 解析边缘设备列表
    edges = JSON.parse(cfg.encode('UTF-8', { invalid: :replace, undef: :replace, replace: '?' }))["edgePage"]["data"]
    data = []
    # 遍历每个边缘设备
    edges.each do |edge|
      # 获取防火墙配置
      firewall_config = cmd "/api/4.0/edges/#{edge['id']}/firewall/config"
      json_config = {}
      # 构建配置数据
      json_config["#{edge['id']} #{edge['name']}"] =
        JSON.parse(firewall_config.encode('UTF-8', { invalid: :replace, undef: :replace, replace: '?' }))
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
