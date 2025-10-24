# 华为 VRP 设备模型
# 支持华为 VRP 网络操作系统的配置备份
class VRP < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配华为 VRP 设备提示符
  prompt /^.*(<[\w.-]+>)$/
  # 注释字符：VRP 使用井号作为注释
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
    # 设置屏幕长度
    post_login 'screen-length 0 temporary'
    # 退出命令
    pre_logout 'quit'
  end

  # 处理版本信息
  cmd 'display version' do |cfg|
    # 过滤掉运行时间和时间戳信息
    cfg = cfg.each_line.reject do |l|
      l.match /uptime|^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d(\.\d\d\d)? ?(\+\d\d:\d\d)?$/
    end.join
    comment cfg
  end

  # 处理设备信息
  cmd 'display device' do |cfg|
    # 过滤掉时间戳信息
    cfg = cfg.each_line.reject { |l| l.match /^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d(\.\d\d\d)? ?(\+\d\d:\d\d)?$/ }.join
    comment cfg
  end

  # 处理当前配置
  cmd 'display current-configuration all' do |cfg|
    # 过滤掉时间戳信息
    cfg = cfg.each_line.reject { |l| l.match /^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d(\.\d\d\d)? ?(\+\d\d:\d\d)?$/ }.join
    cfg
  end
end
