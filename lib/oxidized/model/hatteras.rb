# Hatteras Networks 设备模型
# 支持 Hatteras Networks 网络设备的配置备份
class Hatteras < Oxidized::Model
  using Refinements

  # Hatteras Networks

  # 提示符正则表达式：匹配 Hatteras 设备提示符
  prompt /^(\r?[\w.@()-]+[#>]\s?)$/
  # 注释字符：Hatteras 使用井号作为注释
  comment '# '

  # 处理系统配置警告
  expect /WARNING: System configuration changes will be lost when the device restarts./ do |data, re|
    send "y\r"
    data.sub re, ''
  end

  # 处理敏感信息，隐藏社区字符串和密钥
  cmd :secret do |cfg|
    cfg.gsub! /^(community) \S+/, '\\1 "<configuration removed>"'
    cfg.gsub! /^(communityString) "\S+"/, '\\1 "<configuration removed>"'
    cfg.gsub! /^(key) "\S+"/, '\\1 "<secret hidden>"'
    cfg
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理交换机信息，移除动态信息
  cmd "show switch\r" do |cfg|
    cfg = cfg.each_line.reject do |line|
      line.match(/Switch uptime|Switch temperature|Last reset reason/) ||
        line.match(/TermCpuUtil|^\s+\^$|ERROR: Bad command/)
    end.join
    comment cfg
  end

  # 处理卡信息，移除动态信息
  cmd "show card\r" do |cfg|
    cfg = cfg.each_line.reject do |line|
      line.match(/Card uptime|Card temperature|Last reset reason/) ||
        line.match(/TermCpuUtil|^\s+\^$|ERROR: Bad command/)
    end.join
    comment cfg
  end

  # 处理 SFP 信息
  cmd "show sfp *\r" do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd "show config run\r" do |cfg|
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Login:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    pre_logout "logout\r"
  end
end
