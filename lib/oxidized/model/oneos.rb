# OneOS 设备模型
# 支持 OneOS 网络设备的配置备份
class OneOS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 OneOS 设备提示符
  prompt /^([\w.@()-]+#\s?)$/
  # 注释字符：OneOS 使用感叹号作为注释
  comment  '! '

  # example how to handle pager
  # expect /^\s--More--\s+.*$/ do |data, re|
  #  send ' '
  #  data.sub re, ''
  # end

  # non-preferred way to handle additional PW prompt
  # expect /^[\w.]+>$/ do |data|
  #  send "enable\n"
  #  send vars(:enable) + "\n"
  #  data
  # end

  # 处理所有命令的输出
  cmd :all do |cfg|
    # cfg.gsub! /\cH+\s{8}/, ''         # example how to handle pager
    # cfg.gsub! /\cH+/, ''              # example how to handle pager
    cfg.cut_both
  end

  # 处理敏感信息，隐藏 SNMP 社区字符串
  cmd :secret do |cfg|
    cfg.gsub! /^(snmp set-read-community ").*+?(".*)$/, '\\1<secret hidden>\\2'
    cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理系统硬件信息
  cmd 'show system hardware' do |cfg|
    comment cfg
  end

  # 处理产品信息区域
  cmd 'show product-info-area' do |cfg|
    comment cfg
  end

  # 处理运行配置，移除构建配置信息
  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[0..-1].join
    cfg.gsub! /^Building configuration...\s*[^\n]*\n/, ''
    cfg.gsub! /^Current configuration :\s*[^\n]*\n/, ''
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 处理额外密码的首选方式
    # preferred way to handle additional passwords
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login 'term len 0'
    pre_logout 'exit'
  end
end
