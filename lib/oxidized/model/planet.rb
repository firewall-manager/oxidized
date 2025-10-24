# Planet 设备模型
# 支持 Planet 网络设备的配置备份
class Planet < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 Planet 设备提示符
  prompt /^\r?([\w.@()-]+[#>]\s?)$/
  # 注释字符：Planet 使用感叹号作为注释
  comment  '! '

  # 处理分页器的示例
  # expect /^\s--More--\s+.*$/ do |data, re|
  # send ' '
  # data.sub re, ''
  # end

  # 处理额外密码提示的非首选方式
  # expect /^[\w.]+>$/ do |data|
  #  send "enable\n"
  #  send vars(:enable) + "\n"
  #  data
  # end

  # 处理所有命令的输出
  cmd :all do |cfg|
    # cfg.gsub! /\cH+\s{8}/, ''         # 处理分页器的示例
    # cfg.gsub! /\cH+/, ''              # 处理分页器的示例
    cfg.cut_both
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏 SNMP 社区字符串
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    # 隐藏用户名和权限信息
    cfg.gsub! /username (\S+) privilege (\d+) (\S+).*/, '<secret hidden>'
    # 隐藏用户名密码
    cfg.gsub! /^username \S+ password \d \S+/, '<secret hidden>'
    # 隐藏启用密码
    cfg.gsub! /^enable password \d \S+/, '<secret hidden>'
    # 隐藏 WPA-PSK 密钥
    cfg.gsub! /wpa-psk ascii \d \S+/, '<secret hidden>'
    # 隐藏 TACACS 服务器密钥
    cfg.gsub! /^tacacs-server key \d \S+/, '<secret hidden>'
    cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    cfg.gsub! "\n\r", "\n"
    # 检测 Planet GS 系列设备
    @planetgs = true if cfg =~ /^System Name\w*:\w*GS-.*$/
    # 检测 Planet SGS 系列设备
    @planetsgs = true if cfg =~ /SGS-(.*) Device, Compiled on .*$/

    cfg = cfg.each_line.to_a[0...-2]

    # 移除系统时间和温度信息
    cfg = cfg.reject { |line| line.match /System Time\s*:.*/ }
    cfg = cfg.reject { |line| line.match /System Uptime\s*:.*/ }
    cfg = cfg.reject { |line| line.match /Temperature\s*:.*/ }

    comment cfg.join
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg.gsub! "\n\r", "\n"
    cfg = cfg.each_line.to_a

    # 移除构建配置信息
    cfg = cfg.reject { |line| line.match "Building configuration..." }

    # 如果是 SGS 系列设备，添加收发器详细信息
    if @planetsgs
      cfg << cmd('show transceiver detail | include transceiver detail information|found|Type|length|Nominal|wavelength|Base information') do |cfg_optic|
        comment cfg_optic
      end
    end

    cfg.join
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 设置终端长度
    post_login 'terminal length 0'
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
