# Arris C4 CMTS 设备模型
# 支持 Arris C4 CMTS 的配置备份
class C4CMTS < Oxidized::Model
  using Refinements

  # Arris C4 CMTS

  # 提示符正则表达式：匹配 Arris C4 CMTS 设备提示符
  prompt /^([\w.@:\/-]+[#>]\s?)$/
  # 注释字符：Arris C4 CMTS 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出，清理回车符和空白字符
  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].map { |line| line.delete("\r").rstrip }.join("\n") + "\n"
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    cfg.gsub! /(.+)\s+encrypted-password\s+\w+\s+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /(snmp-server community)\s+".*"\s+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /(tacacs.*\s+key)\s+".*"\s+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /(cable authstring)\s+\w+\s+(.*)/, '\\1 <secret hidden> \\2'
    cfg
  end

  # 处理工厂 EEPROM 信息
  cmd 'show factory-eeprom' do |cfg|
    comment cfg.cut_both
  end

  # 处理版本信息，移除运行时间信息
  cmd 'show version' do |cfg|
    # remove uptime readings at char 55 and beyond
    cfg = cfg.each_line.map { |line| line.rstrip.slice(0..54) }.join("\n") + "\n"
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg.cut_both
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        send vars(:enable) + "\n"
      end
    end
    pre_logout 'exit'
  end
end
