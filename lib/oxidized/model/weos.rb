# Westell WEOS 设备模型
# 支持 Westell WEOS 网络设备的配置备份
# 适用于 Westell 8178G, Westell 8266G
class WEOS < Oxidized::Model
  using Refinements

  # Westell WEOS, works with Westell 8178G, Westell 8266G

  # 提示符正则表达式：匹配 Westell WEOS 设备提示符
  prompt /^(\s[\w.@-]+[#>]\s?)$/

  # 处理所有命令的输出，移除首尾行
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /login:/
    password /assword:/
    post_login 'cli more disable'
    pre_logout 'logout'
  end
end
