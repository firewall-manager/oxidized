# ECI Telecom Apollo 设备模型
# 支持 ECI Telecom Apollo 网络设备的配置备份
# 测试设备：OPT9608 系统，支持 SSH 和 Telnet 连接
# ECI Telecom Apollo
# Tested on OPT9608 systems via SSH and telnet

class ECIapollo < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 ECI Apollo 设备提示符
  prompt /^([\w.@()-]+[#>]\s?)$/
  # 注释字符：ECI Apollo 使用井号作为注释
  comment '# '

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  # 处理敏感信息，隐藏社区字符串和密钥
  cmd :secret do |cfg|
    cfg.gsub!(/community (\S+) {/, 'community <hidden> {')
    cfg.gsub!(/ "\$\d\$\S+; ## SECRET-DATA/, ' <secret removed>;')
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username(/^login:/)
    password(/^Password:/)
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login 'set cli screen-length 0'
    post_login 'set cli screen-width 0'
    pre_logout 'exit'
  end

  # 处理版本信息
  cmd('show version')           { |cfg| comment cfg }
  # 处理系统许可证信息
  cmd('show system licenses')   { |cfg| comment cfg }
  # 处理配置信息
  cmd('show configuration')     { |cfg| comment cfg }
  # 处理配置显示集
  cmd('show configuration | display-set') { |cfg| cfg }
  # 处理机箱库存信息
  cmd('show chassis inventory') { |cfg| comment cfg }
end
