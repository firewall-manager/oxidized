# EdgeCOS 设备模型
# 支持 EdgeCOS 网络设备的配置备份
class EdgeCOS < Oxidized::Model
  using Refinements

  # 注释字符：EdgeCOS 使用感叹号作为注释
  comment '! '

  # 处理分页器（ES3526XA-V2）
  expect /^---More---.*$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏密码
    cfg.gsub!(/password \d+ (\S+).*/, '<secret removed>')
    # 隐藏社区字符串
    cfg.gsub!(/community (\S+)/, 'community <hidden>')
    cfg
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    # 不显示某些设备不支持的命令错误
    cfg.gsub! /^(% Invalid input detected at '\^' marker\.|^\s+\^)$/, ''
    # 处理分页器（ES3526XA-V2）
    cfg.gsub! /^([\b]{10}\s{10}[\b]{10})/, ''
    cfg.cut_both
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    # 移除"构建运行配置，请稍候..."消息
    cfg.gsub! /^Building running configuration.*\n/, ''
    cfg.cut_head
  end

  # 处理系统信息
  cmd 'show system' do |cfg|
    # 移除运行时间信息
    cfg.gsub! /^.*\sUp Time\s*:.*\n/i, ''
    # 隐藏温度值
    cfg.gsub! /(\sTemperature \d*:)\s*\d+ degrees/, '\\1 <temperature values hidden>'
    # 隐藏风扇速度
    cfg.gsub! /^!?\s*Fan \d+ speed:\s+\d+ rpm\s+Fan \d+ speed:\s+\d+ rpm\s+Fan \d+ speed:\s+\d+ rpm$/,
              '<fan speeds hidden>'
    comment cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    # 移除运行时间信息
    cfg.gsub! /^.*\suptime is.*\n/i, ''
    comment cfg
  end

  # 处理看门狗信息
  cmd 'show watchdog' do |cfg|
    comment cfg
  end

  # 处理接口收发器信息
  cmd 'show interfaces transceiver' do |cfg|
    # 移除 DDM 阈值的告警指示器
    cfg.gsub! /(\d\d)!/, '\\1 '
    # 隐藏温度信息
    cfg.gsub! /^(\s*Temperature\s*:).*/, '\1 <hidden>'
    # 隐藏 Vcc 信息
    cfg.gsub! /^(\s*Vcc\s*:).*/, '\1 <hidden>'
    # 隐藏偏置电流信息
    cfg.gsub! /^(\s*Bias Current\s*:).*/, '\1 <hidden>'
    # 隐藏发送功率信息
    cfg.gsub! /^(\s*TX Power\s*:).*/, '\1 <hidden>'
    # 隐藏接收功率信息
    cfg.gsub! /^(\s*RX Power\s*:).*/, '\1 <hidden>'
    comment cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login do
      # 启用特权模式
      send "enable\n" if vars(:enable) == true
    end
    # 设置终端长度为 0
    post_login 'terminal length 0'
    # 设置终端宽度为 300
    post_login 'terminal width 300'
    # 退出命令
    pre_logout 'exit' if vars(:enable) == true
    pre_logout 'exit'
  end
end
