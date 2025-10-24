# 齐科 (QTECH) 设备模型
# 支持齐科网络设备的配置备份
class QTECH < Oxidized::Model
  using Refinements

  # 注释字符：齐科使用感叹号作为注释
  comment '! '

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏 SNMP 社区字符串
    cfg.gsub! /^(snmp-server community(?: r[ow])?(?: \d)?) .+/, '\\1 <secret hidden>'
    # 隐藏 SNMP 用户认证信息
    cfg.gsub! /^(snmp-server user .+ auth \S+) .+/, '\\1 <secret hidden>'
    # 隐藏用户名和密码
    cfg.gsub! /^(username .+ password \d) .+/, '\\1 <secret hidden>'
    # 隐藏启用密码
    cfg.gsub! /^(enable password(?: level \d+)? \d) .+/, '\\1 <secret hidden>'
    cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg.each_line.reject { |line|
      line.match /^  (Copyright |All rights reserved$|Uptime is |Last reboot is )/
    }.join
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^login:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
      # 设置终端长度
      cmd 'terminal length 0'
    end
    # 退出命令
    pre_logout 'exit'
  end
end
