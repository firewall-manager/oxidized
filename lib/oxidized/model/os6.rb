# OS6 设备模型
# 支持运行 Dell EMC Networking OS6 的交换机
# 测试过的设备：Dell PowerSwitch N2048
class OS6 < Oxidized::Model
  using Refinements

  # 注释字符：OS6 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出
  cmd :all do |cfg|
    # 移除无效输入标记
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.each_line.to_a[2..-2].join
  end

  # 处理敏感信息，隐藏密码
  cmd :secret do |cfg|
    # 隐藏密码
    cfg.gsub! /(password )(\S+)/, '\1<secret hidden>'
    cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理接口收发器属性信息
  cmd 'show interfaces transceiver properties' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
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
        # 启用特权模式
        send "enable\n"
        cmd vars(:enable)
      end
    end
    # 设置终端长度
    post_login 'terminal length 0'
    # 退出命令
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
