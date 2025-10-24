# Comnet Microsemi 设备模型
# 支持 Comnet Microsemi 交换机的配置备份
class ComnetMS < Oxidized::Model
  using Refinements

  # Comnet Microsemi Switch
  # 提示符正则表达式：匹配 Comnet Microsemi 设备提示符
  prompt /^\r?([\w.@()-]+[#>]\s?)$/
  # 注释字符：Comnet Microsemi 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出，移除首尾行
  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  # 处理运行配置，清理格式
  cmd 'show running-config' do |cfg|
    cfg.gsub! "\n\r", "\n"
    cfg.gsub! /^[\r\n\s]*Building configuration\.\.\.\n/, ''
    cfg.gsub! /^end\n/, ''
    cfg
  end

  # 处理版本信息，移除动态信息
  cmd 'show version' do |cfg|
    cfg.gsub! "\n\r", "\n"
    cfg.gsub! /^MEMORY\s*:.*\n/, ''
    cfg.gsub! /^FLASH\s*:.*\n/, ''
    cfg.gsub! /^Previous Restart\s*:.*\n/, ''
    cfg.gsub! /^System Time\s*:.*\n/, ''
    cfg.gsub! /^System Uptime\s*:.*\n/, ''
    comment cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/i
    password /^Password:/i
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
  end
end
