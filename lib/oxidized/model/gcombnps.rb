# GCOM BNPS 设备模型
# 支持 GCOM Technologies Co.,Ltd. 运行 "Broadband Network Platform Software" 的交换机
# 作者：Frederik Kriewitz <frederik@kriewitz.eu>
#
# 测试过的设备：
#  - S5330 (又名 Fiberstore S3800)
class GcomBNPS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 GCOM BNPS 设备提示符
  # 也匹配 SSH 密码提示符（post_login 命令在第一个提示符后发送）
  prompt /^\r?([\w.@()-]+?(\(1-\d+ chars\))?[#>:]\s?)$/
  # 注释字符：GCOM BNPS 使用感叹号作为注释
  comment '! '

  # 处理 SSH 登录的替代方法，但这会破坏 telnet
  #  expect /^Password\(1-\d+ chars\):/ do |data|
  #      send @node.auth[:password] + "\n"
  #      ''
  #  end

  # 处理分页器（无法禁用？）
  expect /^\.\.\.\.press ENTER to next line, CTRL_C to quit, other key to next page\.\.\.\.$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    # 移除分页器留下的垃圾字符
    cfg = cfg.gsub " \e[73D\e[K", ''
    cfg.cut_both
  end

  # 处理敏感信息，隐藏 SNMP 社区字符串
  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community)\s+[^\s]+\s+(.*)/, '\\1 <community hidden> \\2'
    cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg
  end

  # 处理 SFP 接口信息
  cmd 'show interface sfp' do |cfg|
    out = []
    cfg.each_line do |line|
      # 跳过温度信息
      next if line =~ /^  Temperature/
      # 跳过电压信息
      next if line =~ /^  Voltage\(V\)/
      # 跳过偏置电流信息
      next if line =~ /^  Bias Current\(mA\)/
      # 跳过接收功率信息
      next if line =~ /^  RX Power\(dBM\)/
      # 跳过发送功率信息
      next if line =~ /^  TX Power\(dBM\)/

      out << line
    end

    comment out.join
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理系统信息
  cmd 'show system' do |cfg|
    out = []
    cfg.each_line do |line|
      # 跳过系统运行时间信息
      next if line =~ /^system run time        :/
      # 跳过交换机温度信息
      next if line =~ /^switch temperature     :/

      out << line
    end

    comment out.join
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username\(1-\d+ chars\):/
    password /^Password\(1-\d+ chars\):/
  end

  # SSH 连接配置
  # 注意：此设备有特殊的 SSH 行为
  cfg :ssh do
    # 交换机盲目接受 SSH 连接而不进行密码验证，然后生成 telnet 登录提示符
    # 我们首先要发送的是密码
    # 这种设备在 SSH 连接后仍需要密码验证，与标准 SSH 不同
    post_login do
      send @node.auth[:password] + "\n"
    end
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 退出命令
    pre_logout 'exit'
  end
end
