# HPE BladeSystem 设备模型
# 支持 HPE Onboard Administrator 的配置备份
class HPEBladeSystem < Oxidized::Model
  using Refinements

  # HPE Onboard Administrator

  # 提示符正则表达式：匹配 HPE BladeSystem 设备提示符
  prompt /.*> /
  # 注释字符：HPE BladeSystem 使用井号作为注释
  comment '# '

  # expect /^\s*--More--\s+.*$/ do |data, re|
  #   send ' '
  #   data.sub re, ''
  # end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg = cfg.delete("\r").each_line.to_a[0..-1].map { |line| line.rstrip }.join("\n") + "\n"
    cfg.cut_tail
  end

  # 处理敏感信息，隐藏 SNMP 社区字符串
  cmd :secret do |cfg|
    cfg.gsub! /^(SET SNMP COMMUNITY (READ|WRITE)).*/, '\\1 <configuration removed>'
    cfg
  end

  # 处理 OA 信息
  cmd 'show oa info' do |cfg|
    comment cfg
  end

  # 处理 OA 网络信息
  cmd 'show oa network' do |cfg|
    comment cfg
  end

  # 处理 OA 证书信息
  cmd 'show oa certificate' do |cfg|
    comment cfg
  end

  # 处理 SSH 指纹信息
  cmd 'show sshfingerprint' do |cfg|
    comment cfg
  end

  # 处理 FRU 信息
  cmd 'show fru' do |cfg|
    comment cfg
  end

  # 处理网络信息，移除最后更新时间
  cmd 'show network' do |cfg|
    cfg.gsub! /Last Update:.*$/i, ''
    comment cfg
  end

  # 处理 VLAN 信息
  cmd 'show vlan' do |cfg|
    comment cfg
  end

  # 处理机架名称
  cmd 'show rack name' do |cfg|
    comment cfg
  end

  # 处理服务器列表
  cmd 'show server list' do |cfg|
    comment cfg
  end

  # 处理服务器名称
  cmd 'show server names' do |cfg|
    comment cfg
  end

  # 处理服务器端口映射
  cmd 'show server port map all' do |cfg|
    comment cfg
  end

  # 处理服务器信息
  cmd 'show server info all' do |cfg|
    comment cfg
  end

  # 处理配置信息，移除生成时间
  cmd 'show config' do |cfg|
    cfg.gsub! /^(#Generated on:) .*$/, '\\1 <removed>'
    cfg.gsub /^\s+/, ''
  end

  # Telnet 连接配置
  cfg :telnet do
    username /\slogin:/
    password /^Password: /
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login "set script mode on"
    pre_logout "exit"
  end
end
