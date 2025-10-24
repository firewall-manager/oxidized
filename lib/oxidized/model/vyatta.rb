# Brocade Vyatta 设备模型
# 支持 Brocade Vyatta 网络设备的配置备份
class Vyatta < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 Vyatta 设备提示符
  prompt /@.*(:~\$|>)\s/

  # 处理所有命令的输出，移除第一行和最后一行
  cmd :all do |cfg|
    cfg.lines.to_a[1..-2].join
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏加密密码
    cfg.gsub! /encrypted-password (\S+).*/, 'encrypted-password <secret removed>'
    # 隐藏明文密码
    cfg.gsub! /plaintext-password (\S+).*/, 'plaintext-password <secret removed>'
    # 隐藏密码
    cfg.gsub! /password (\S+).*/, 'password <secret removed>'
    # 隐藏预共享密钥
    cfg.gsub! /pre-shared-secret (\S+).*/, 'pre-shared-secret <secret removed>'
    # 隐藏 SNMP 社区字符串
    cfg.gsub! /community (\S+)/, 'community <hidden>'
    # 隐藏私钥
    cfg.gsub! /private-key (\S+).*/, 'private-key <secret removed>'
    # 隐藏预共享密钥
    cfg.gsub! /preshared-key (\S+).*/, 'preshared-key <secret removed>'
    cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 获取配置命令
  cmd 'show configuration commands | no-more'

  # Telnet 连接配置
  cfg :telnet do
    username  /login:\s/
    password  /^Password:\s/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 退出命令
    pre_logout 'exit'
  end
end
