# VMware NSX 分布式防火墙模型
# 支持 VMware NSX 分布式防火墙的配置备份
require 'net/http'
class NSXDfw < Oxidized::Model
  using Refinements

  # 处理分布式防火墙策略配置
  cmd "/policy/api/v1/infra/domains/" do |cfg|
    domains = JSON.parse(cfg.encode('UTF-8', { invalid: :replace, undef: :replace, replace: '?' }))["results"]
    domain_config = {}
    domains.each do |domain|
      domain_config[domain['id']] = {}
      policies_data = cmd "/policy/api/v1/infra/domains/#{domain['id']}/security-policies/"
      policies = JSON.parse(policies_data.encode('UTF-8',
                                                 { invalid: :replace, undef: :replace, replace: '?' }))["results"]
      policies_config = {}
      policies.each do |policy|
        rules_data = cmd "/policy/api/v1/infra/domains/#{domain['id']}/security-policies/#{policy['id']}/rules"
        rules = JSON.parse(rules_data.encode('UTF-8', { invalid: :replace, undef: :replace, replace: '?' }))["results"]
        policies_config[policy['id']] = rules
      end
      domain_config[domain['id']] = policies_config
    end
    JSON.pretty_generate(domain_config)
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
