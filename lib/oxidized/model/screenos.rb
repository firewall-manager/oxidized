# ScreenOS 设备模型
# 支持 Netscreen ScreenOS 防火墙的配置备份
class ScreenOS < Oxidized::Model
  using Refinements

  # 注释字符：ScreenOS 使用感叹号作为注释
  comment '! '

  # 提示符正则表达式：匹配 ScreenOS 设备提示符
  prompt /^[\w.:()-]+->\s?$/

  # 处理所有命令的输出
  cmd :all do |cfg|
    # 移除第一行和最后一行
    cfg.each_line.to_a[1..-2].join
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏管理员名称和密码
    cfg.gsub! /^(set admin name) .*|^(set admin password) .*/, '\\1 <removed>'
    # 隐藏管理员用户密码
    cfg.gsub! /^(set admin user .* password) .* (.*)/, '\\1 <removed> \\2'
    # 隐藏密钥、密码和预共享密钥
    cfg.gsub! /(secret|password|preshare) .*/, '\\1 <secret hidden>'
    cfg
  end

  # 处理系统信息
  cmd 'get system' do |cfg|
    # 移除日期信息
    cfg.gsub! /^Date .*\n/, ''
    # 移除运行时间信息
    cfg.gsub! /^Up .*\n/, ''
    # 移除当前带宽信息
    cfg.gsub! /(current bw ).*/, '\\1 <removed>'
    comment cfg
  end

  # 处理配置信息
  cmd 'get config' do |cfg|
    # 移除第一行
    cfg.each_line.to_a[1..-1].join
  end

  # Telnet 连接配置
  cfg :telnet do
    username '/^login:/'
    password '/^password:/'
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 设置控制台分页为 0
    post_login 'set console page 0'
    pre_logout do
      # 退出命令
      send "exit\n"
      send "n"
    end
  end
end
