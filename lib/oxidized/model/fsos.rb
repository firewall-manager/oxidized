# FSOS 设备模型
# 支持 Fiberstore / fs.com 网络设备的配置备份
class FSOS < Oxidized::Model
  using Refinements
  # 注释字符：FSOS 使用感叹号作为注释
  comment '! '
  # 提示符正则表达式：匹配 FSOS 设备提示符
  prompt /^([\w.@()-]+[#>]\s?)$/

  # 处理分页器
  expect /^ --More--.*$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏密钥
    cfg.gsub! /(secret \w+) (\S+).*/, '\\1 <secret hidden>'
    # 隐藏密码
    cfg.gsub! /(password \d+) (\S+).*/, '\\1 <secret hidden>'
    # 隐藏 SNMP 服务器社区字符串
    cfg.gsub! /(snmp-server community \d+) (\S+).*/, '\\1 <secret hidden>'
    # 隐藏 SNMP 服务器主机密钥
    cfg.gsub! /^(snmp-server host \S+( udp-port \d+)?( permit|deny \d+)?( informs?)?( traps?)?(( version v3 (priv|auth|noauth))|( version (v1|v2c))?)) +\S+( .*)?$*/, '\\1 <secret hidden>'
    # 隐藏 SNMP 服务器用户密钥
    cfg.gsub! /^(snmp-server user \S+ \S+ v3( priv (des|aes128|aes256|aes256-c))?( auth (md5|sha|sha256) \d+)) +\S+( .*)?$*/, '\\1 <secret hidden>'
    # 隐藏其他密钥
    cfg.gsub! /^(.*key \d+) (\S+).*/, '\\1 <secret hidden>'
    cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    # 移除运行时间信息，使结果不会每次都改变
    cfg.gsub! /.*uptime is.*\n/, ''
    cfg.gsub! /.*System uptime.*\n/, ''
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    # 移除"Building configuration..."消息
    cfg.gsub! /^Building configuration.*\n/, ''
    cfg.cut_head
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 启用特权模式
    post_login 'enable'
    # 设置终端长度
    post_login 'terminal length 0'
    # 设置终端宽度
    post_login 'terminal width 512'
    # 退出命令
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
