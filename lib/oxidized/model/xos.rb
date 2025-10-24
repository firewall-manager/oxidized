# Extreme Networks XOS 设备模型
# 支持 Extreme Networks XOS 网络设备的配置备份
class XOS < Oxidized::Model
  using Refinements

  # Extreme Networks XOS

  # 提示符正则表达式：匹配 Extreme Networks XOS 设备提示符
  prompt /^\s?\*?\s?[-\w]+\s?[-\w.~]+(:\d+)? [#>] $/
  # 注释字符：XOS 使用井号作为注释
  comment  '# '

  # 处理所有命令的输出，清理回车符和尾随空白字符
  cmd :all do |cfg|
    # xos inserts leading \r characters and other trailing white space.
    # this deletes extraneous \r and trailing white space.
    cfg.each_line.to_a[1..-2].map { |line| line.delete("\r").rstrip }.join("\n") + "\n"
  end

  # 处理敏感信息，隐藏 RADIUS 共享密钥、管理员账户和用户账户密码
  cmd :secret do |cfg|
    cfg.gsub! /^(configure (radius|radius-accounting) (netlogin|mgmt-access) (primary|secondary) shared-secret encrypted).+/, '\\1 <secret hidden>'
    cfg.gsub! /^(configure account admin encrypted).+/, '\\1 <secret hidden>'
    cfg.gsub! /^(create account (admin|user) (.+) encrypted).+/, '\\1 <secret hidden>'
    cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理诊断信息
  cmd 'show diagnostics' do |cfg|
    comment cfg
  end

  # 处理许可证信息
  cmd 'show licenses' do |cfg|
    comment cfg
  end

  # 处理交换机信息，移除时间相关和启动信息
  cmd 'show switch' do |cfg|
    cfg.gsub! /Next periodic save on.*/, ''
    comment cfg.each_line.reject { |line|
      line.match(/Time:/) || line.match(/boot/i) || line.match(/Next periodic/)
    }.join
  end

  # 处理配置信息，移除配置生成信息
  cmd 'show configuration' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match /^#(\s[\w -]+\s)(Configuration generated)/ }.join
    cfg
  end

  # 处理策略详细信息
  cmd 'show policy detail' do |cfg|
    comment cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^login:/
    password /^\r*password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login do
      data = cmd 'disable clipaging session'
      match = data.match /^disable clipaging session\n\r?\*?\s?[-\w]+\s?[-\w.~]+(:\d+)? [#>] $/m
      next if match

      cmd 'disable clipaging'
    end

    pre_logout do
      send "exit\n"
      send "n\n"
    end
  end
end
