# Force10 DNOS 设备模型
# 支持 Force10 DNOS 网络设备的配置备份
class DNOS < Oxidized::Model
  using Refinements

  # Force10 DNOS model #

  # 注释字符：DNOS 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出，清理错误信息和动态信息
  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.gsub! /(uptime is)(\s.+)/, '\\1 <removed>' # Omit changing uptime info
    cfg.each_line.to_a[2..-2].join
  end

  # 处理敏感信息，隐藏各种密码和密钥
  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /secret (\d+) (\S+).*/, '<secret hidden>'
    cfg.gsub! /password (\d+) (\S+).*/, '<secret hidden>'
    cfg.gsub! /^(tacacs-server key \d+) (\S+).*/, '\\1 <secret hidden>'
    cfg.gsub! /(ip ospf message-digest-key \d \S+ \d).*/, '\\1 <secret hidden>'
    cfg.gsub! /(authentication-type).*/, '\\1 <secret hidden>'
    cfg.gsub! /^(bsd-username \S+ secret).*/, '\\1 <secret hidden>'
    cfg
  end

  # 处理设备清单信息
  cmd 'show inventory' do |cfg|
    comment cfg
  end

  # 处理介质清单信息
  cmd 'show inventory media' do |cfg|
    comment cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-1].join
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Login:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
