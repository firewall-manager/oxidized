# Ubiquiti EdgeOS 设备模型
# 支持 Ubiquiti EdgeOS 网络设备的配置备份
class Edgeos < Oxidized::Model
  using Refinements

  # Ubiquiti EdgeOS #

  # 提示符正则表达式：匹配 EdgeOS 设备提示符
  prompt /@.*?:~\$\s/

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.lines.to_a[1..-2].join
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    cfg.gsub!(/(encrypted-password) \S+/, '\1 <secret removed>')
    cfg.gsub!(/(plaintext-password) \S+/, '\1 <secret removed>')
    cfg.gsub!(/(password) \S+/, '\1 <secret removed>')
    cfg.gsub!(/(pre-shared-secret) \S+/, '\1 <secret removed>')
    cfg.gsub!(/(community) \S+ {/, '\1 <hidden> {')
    cfg.gsub!(/(commit-archive location) \S+/, '\1 <secret removed>')
    cfg
  end

  # 处理版本信息，移除运行时间
  cmd 'show version | no-more' do |cfg|
    cfg.gsub! /^Uptime:\s.+/, ''
    comment cfg
  end

  # 处理配置命令
  cmd 'show configuration commands | no-more'

  # Telnet 连接配置
  cfg :telnet do
    username  /login:\s/
    password  /^Password:\s/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    pre_logout 'exit'
  end
end
