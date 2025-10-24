# SAOS 设备模型
# 支持 Ciena SAOS 交换机的配置备份
# 用于 6.x 版本的设备
class SAOS < Oxidized::Model
  using Refinements

  # Ciena SAOS switch
  # used for 6.x devices

  # 注释字符：SAOS 使用感叹号作为注释
  comment '! '
  # 提示符正则表达式：匹配 SAOS 设备提示符
  prompt /^[\w-]+\*?>\s?/

  # 处理所有命令的输出，移除 TACACS 错误
  cmd :all do |cfg|
    cfg.gsub! /(Waiting for )(accounting|authorization).*\n/, '' # Remove TACACS errors
    cfg.cut_both
  end

  # 处理机箱设备 ID 和电源信息
  cmd 'chassis show device-id power' do |cfg|
    comment cfg
  end

  # 处理软件信息，移除银行状态信息
  cmd 'software show' do |cfg|
    cfg.gsub! /^\| Bank status.*/, '| Bank status         : <removed>                                              |'
    comment cfg
  end

  # 处理端口收发器信息，移除瞬态操作状态
  cmd 'port xcvr show' do |cfg|
    cfg.gsub! /^SHELL PARSER FAILURE.*/, '' # Ignore command failure
    cfg.gsub! /(\s\|.{10}\|)(Ena\s\s|\s\sDis|UCTF\s)(.*)/, '\1     \3' # Remove transient operational state
    comment cfg
  end

  # 处理配置显示，移除创建时间和终端信息
  cmd 'configuration show' do |cfg|
    cfg.gsub! /^! Created: [^\n]*\n/, ''
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
    post_login 'system shell set more off'
    post_login 'system shell session set more off'
    pre_logout 'exit'
  end
end
