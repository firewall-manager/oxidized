# Dell EMC OS10 设备模型
# 支持运行 Dell EMC Networking OS10 的交换机
# 测试设备：Dell PowerSwitch S4148U-ON
class OS10 < Oxidized::Model
  using Refinements

  # For switches running Dell EMC Networking OS10 #
  #
  # Tested with : Dell PowerSwitch S4148U-ON

  # 注释字符：OS10 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出，清理错误信息
  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.each_line.to_a[2..-2].join
  end

  # 处理敏感信息，隐藏密码
  cmd :secret do |cfg|
    cfg.gsub! /(password )(\S+)/, '\1<secret hidden>'
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

  # 处理运行配置
  cmd 'show running-configuration' do |cfg|
    cfg.each_line.to_a[3..-1].join
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
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
