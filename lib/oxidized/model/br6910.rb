# Brocade BR6910 设备模型
# 支持 Brocade BR6910 系列交换机的配置备份
class BR6910 < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 BR6910 设备提示符
  prompt /^([\w.@()-]+[#>]\s?)$/
  # 注释字符：BR6910 使用感叹号作为注释
  comment '! '

  # 处理分页器（在 show running-config 之前无法禁用分页）
  # not possible to disable paging prior to show running-config
  expect /^((.*)Others to exit ---(.*))$/ do |data, re|
    send 'a'
    data.sub re, ''
  end

  # 处理所有命令的输出，标准化空白字符
  cmd :all do |cfg|
    # sometimes br6910s inserts arbitrary whitespace after commands are
    # issued on the CLI, from run to run.  this normalises the output.
    cfg.each_line.to_a[1..-2].drop_while { |e| e.match /^\s+$/ }.join
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理目录信息（BR6910 不支持 show flash，使用 dir 查看闪存内容）
  # show flash is not possible on a brocade 6910, do dir instead
  # to see flash contents (includes config file names)
  cmd 'dir' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    arr = cfg.each_line.to_a
    arr[2..-1].join unless arr.length < 2
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  # post login and post logout
  cfg :telnet, :ssh do
    post_login ''
    pre_logout 'exit'
  end
end
