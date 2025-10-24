# Cisco Catalyst OS 设备模型
# 支持 Cisco Catalyst 系列交换机的配置备份
class Catos < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 CatOS 设备提示符
  prompt /^[\w.@-]+>\s?(\(enable\) )?$/
  # 注释字符：CatOS 使用井号作为注释
  comment '# '

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理系统信息
  cmd 'show system' do |cfg|
    # 隐藏时间信息
    cfg = cfg.gsub /(\s+)\d+,\d+:\d+:\d+(\s+)/, '\1X\2'
    comment cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    # 隐藏内存大小信息
    cfg = cfg.gsub /\d+(K)/, 'X\1'
    # 隐藏运行时间信息
    cfg = cfg.gsub /^(Uptime is ).*/, '\1X'
    comment cfg
  end

  # 处理完整配置
  cmd 'show conf all' do |cfg|
    # 隐藏时间戳信息
    cfg = cfg.sub /^(#time: ).*/, '\1X'
    # 从 "begin" 行开始处理配置
    cfg.each_line.drop_while { |line| not line.match /^begin/ }.join
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username: /
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 设置终端长度
    post_login 'set length 0'
    # 处理额外密码的首选方式
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    # 退出命令
    pre_logout 'exit'
  end
end
