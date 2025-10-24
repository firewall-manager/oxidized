# VyOS 设备模型
# 支持 VyOS 网络操作系统的配置备份
# VyOS 是 Vyatta 的分支，正在积极开发中
# https://vyos.org/
class Vyos < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 VyOS 设备提示符
  prompt /^\S+@\S+(:~\$|>) $/
  # 清理转义代码
  clean :escape_codes

  # 处理所有命令的输出，移除第一行和最后一行
  cmd :all do |cfg|
    cfg.lines.to_a[1..-2].join
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏密钥
    cfg.gsub! /secret (\S+).*/, 'secret <secret removed>'
    # 隐藏密码
    cfg.gsub! /password (\S+).*/, 'password <secret removed>'
    # 隐藏 SNMP 社区字符串
    cfg.gsub! /community (\S+)/, 'community <secret removed>'
    # 隐藏私钥
    cfg.gsub! /private key (\S+).*/, 'private key <secret removed>'
    # 隐藏 URL 中的密码，如 protocol://user:password@domain.tld/
    cfg.gsub! /([a-z]+:\/\/[^:\s]+:)\S+@/, '\1<secret removed>@'
    cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 获取配置命令
  cmd 'show configuration commands | no-more'

  # SSH 连接配置
  cfg :ssh do
    # 退出命令
    pre_logout 'exit'
  end
end
