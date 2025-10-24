# H3C 设备模型
# 支持 H3C 网络设备的配置备份
class H3C < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 H3C 设备提示符
  prompt /^.*([<\[][\w.-]+[>\]])$/
  # 注释字符：H3C 使用井号作为注释
  comment '# '

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏 PIN 验证信息
    cfg.gsub! /(pin verify (?:auto|)).*/, '\\1 <PIN hidden>'
    # 隐藏加密的密钥信息
    cfg.gsub! /(%\^%#.*%\^%#)/, '<secret hidden>'
    cfg
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:$/
    password /^Password:$/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 禁用屏幕长度
    post_login 'screen-length disable'
    # 退出命令
    pre_logout 'quit'
  end

  # 处理版本信息
  cmd 'display version' do |cfg|
    # 过滤掉运行时间信息
    cfg = cfg.each_line.reject { |l| l.match /uptime/ }.join
    cfg = cfg.each_line.reject { |l| l.match /Uptime is/ }.join
    comment cfg
  end

  # 处理设备信息
  cmd 'display device' do |cfg|
    comment cfg
  end

  # 处理当前配置
  cmd 'display current-configuration' do |cfg|
    cfg
  end
end
