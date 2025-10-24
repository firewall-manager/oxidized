# Cisco IOS XR 设备模型
# 支持 Cisco IOS XR 系列路由器的配置备份
class IOSXR < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 IOS XR 设备提示符
  prompt /^(\r?[\w.@:\/-]+[#>]\s?)$/
  # 注释字符：IOS XR 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出，移除前两行和后两行
  cmd :all do |cfg|
    cfg.each_line.to_a[2..-2].join
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏 SNMP 社区字符串
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    # 隐藏密钥
    cfg.gsub! /secret (\d+) (\S+).*/, '<secret hidden>'
    cfg
  end

  # 处理设备清单信息
  cmd 'show inventory all' do |cfg|
    comment cfg
  end

  # 处理平台信息
  cmd 'show platform' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    # 移除第一行（通常是命令本身）
    cfg = cfg.each_line.to_a[1..-1].join
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/
    password /^\r?Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 设置终端长度和宽度
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    # 设置终端执行提示符无时间戳
    post_login 'terminal exec prompt no-timestamp'
    if vars :enable
      post_login do
        send "enable\n"
        send vars(:enable) + "\n"
      end
    end
    # 退出命令
    pre_logout 'exit'
  end
end
