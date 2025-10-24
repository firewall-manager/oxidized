# SLXOS 设备模型
# 支持 Brocade SLXOS 网络设备的配置备份
class SLXOS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 SLXOS 设备提示符
  prompt /^.*[>#]\s?$/i
  # 注释字符：SLXOS 使用感叹号作为注释
  comment '! '

  # 处理版本信息，移除系统运行时间
  cmd 'show version' do |cfg|
    cfg.gsub! /(^((.*)[Ss]ystem [Uu]ptime(.*))$)/, '' # remove unwanted line system uptime
    cfg.gsub! /[Uu]p\s?[Tt]ime is .*/, ''

    comment cfg
  end

  # 处理机箱信息，清理编码和动态信息
  cmd 'show chassis' do |cfg|
    cfg.encode!("UTF-8", invalid: :replace, undef: :replace) # sometimes ironware returns broken encoding
    cfg.gsub! /.*Power Usage.*/, '' # remove unwanted lines power usage
    cfg.gsub! /^Update:.*$/, '' # remove unwanted current date
    cfg.gsub! /Time A(live|wake).*/, '' # remove unwanted lines time alive/awake
    cfg.gsub! /(\[*)1(\]*)<->(\[*)2(\]*)(<->(\[*)3(\]*))*/, ''

    comment cfg
  end

  # 处理系统信息，移除运行时间和风扇速度
  cmd 'show system' do |cfg|
    cfg.gsub! /Up Time.*/, '' # removes uptime line
    cfg.gsub! /Current Time.*/, '' # remove current time line
    cfg.gsub! /.*speed is.*/, '' # removes fan speed lines

    comment cfg
  end

  # 处理插槽信息，处理固定配置设备
  cmd 'show slots' do |cfg|
    cfg.gsub! /^-*^$/, '' # some slx devices are fixed config
    cfg.gsub! "syntax error: element does not exist", '' # same as above

    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    arr = cfg.each_line.to_a
    arr[2..-1].join unless arr.length < 2
  end

  # Telnet 连接配置
  cfg :telnet do
    # match expected prompts
    username /^(Please Enter Login Name|Username):/
    password /^(Please Enter Password ?|Password):/
  end

  # Telnet 和 SSH 连接配置，处理分页器和启用密码
  # handle pager with enable
  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login ''
    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
