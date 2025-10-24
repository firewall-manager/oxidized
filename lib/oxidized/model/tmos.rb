# F5 TMOS 设备模型
# 支持 F5 TMOS (Traffic Management Operating System) 的配置备份
class TMOS < Oxidized::Model
  using Refinements

  # 注释字符：TMOS 使用井号作为注释
  comment '# '

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    cfg.gsub!(/^([\s\t]*)secret \S+/, '\1secret <secret removed>')
    cfg.gsub!(/^([\s\t]*\S*)password \S+/, '\1password <secret removed>')
    cfg.gsub!(/^([\s\t]*\S*)passphrase \S+/, '\1passphrase <secret removed>')
    cfg.gsub!(/community \S+/, 'community <secret removed>')
    cfg.gsub!(/community-name \S+/, 'community-name <secret removed>')
    cfg.gsub!(/^([\s\t]*\S*)encrypted \S+$/, '\1encrypted <secret removed>')
    cfg
  end

  # 处理系统版本信息
  cmd('tmsh -q show sys version') { |cfg| comment cfg }

  # 处理系统软件信息
  cmd('tmsh -q show sys software') { |cfg| comment cfg }

  # 处理系统硬件信息，移除动态数据
  cmd 'tmsh -q show sys hardware field-fmt' do |cfg|
    cfg.gsub!(/fan-speed (\S+)/, '')
    cfg.gsub!(/temperature (\S+)/, '')
    cfg.gsub!(/humidity (\S+)/, '')
    comment cfg
  end

  # 处理许可证信息
  cmd('cat /config/bigip.license') { |cfg| comment cfg }

  # 处理配置列表，移除动态状态信息
  cmd 'tmsh -q list' do |cfg|
    cfg.gsub!(/state (up|down|checking|irule-down)/, '')
    cfg.gsub!(/errors (\d+)/, '')
    cfg.gsub!(/^\s+bandwidth-bps (\d+)/, '')
    cfg.gsub!(/^\s+bandwidth-cps (\d+)/, '')
    cfg.gsub!(/^\s+bandwidth-pps (\d+)\n/, '')
    cfg.gsub!(/^\s*\S*encrypted \S+\n/, '')
    cfg
  end

  # 处理网络路由信息
  cmd('tmsh -q list net route all') { |cfg| comment cfg }

  # 处理 SSL 证书信息
  cmd('/bin/ls --full-time --color=never /config/ssl/ssl.crt') { |cfg| comment cfg }

  # 处理 SSL 密钥信息
  cmd('/bin/ls --full-time --color=never /config/ssl/ssl.key') { |cfg| comment cfg }

  # 处理运行配置数据库属性，移除时间戳
  cmd 'tmsh -q show running-config sys db all-properties' do |cfg|
    cfg.gsub!(/sys db configsync.localconfigtime {[^}]+}/m, '')
    cfg.gsub!(/sys db gtm.configtime {[^}]+}/m, '')
    cfg.gsub!(/sys db ltm.configtime {[^}]+}/m, '')
    comment cfg
  end

  # 处理 ZebOS 配置
  cmd('[ -d "/config/zebos" ] && cat /config/zebos/*/ZebOS.conf') { |cfg| comment cfg }

  # 处理分区配置
  cmd('cat /config/partitions/*/bigip*.conf') { |cfg| comment cfg }

  # SSH 连接配置
  cfg :ssh do
    exec true # don't run shell, run each command in exec channel
  end
end
