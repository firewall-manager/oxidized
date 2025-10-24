# SAOS10 设备模型
# 支持 Ciena SAOS 交换机的配置备份
# 用于 10.x 版本的设备
class SAOS10 < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 SAOS10 设备提示符
  prompt /^[\w-]+\*?> ?$/
  # 注释字符：SAOS10 使用井号作为注释
  comment  '# '

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理系统主机名信息
  cmd('show system hostname') { |cfg| comment cfg }

  # 处理软件信息
  cmd('show software') { |cfg| comment cfg }

  # 处理系统组件信息
  cmd('show system components') { |cfg| comment cfg }

  # 处理系统健康状态信息
  cmd('show system health') { |cfg| comment cfg }

  # 处理系统最后重置原因信息
  cmd('show system last-reset-reasons') { |cfg| comment cfg }

  # 处理运行配置
  cmd 'show running config' do |cfg|
    # 移除创建时间信息
    cfg.gsub! /^! Created: [^\n]*\n/, ''
    # 移除终端信息
    cfg.gsub! /^! On terminal: [^\n]*\n/, ''
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /login:/
    password /assword:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 禁用分页器
    post_login 'set session more off'
    # 退出命令
    pre_logout 'exit'
  end
end
