# frozen_string_literal: true

# Juniper JunOS 设备模型
# 支持 Juniper 网络设备的配置备份
class JunOS < Oxidized::Model
  using Refinements
  # 注释字符：Juniper 使用井号作为注释
  comment '# '

  # 检查是否为 Telnet 连接
  # @return [Boolean] 如果是 Telnet 连接则返回 true
  def telnet
    @input.class.to_s.match(/Telnet/)
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg = cfg.cut_both if screenscrape
    # 隐藏规模订阅者数量
    cfg.gsub!(/  scale-subscriber (\s+)(\d+)/, '  scale-subscriber                <count>')
    # 隐藏 VMX 带宽信息
    cfg.gsub!(/VMX-BANDWIDTH\s+(\d+) (.*)/, 'VMX-BANDWIDTH                  <count> \2')
    cfg.lines.map { |line| line.rstrip }.join("\n") + "\n"
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏 SNMP 社区字符串
    cfg.gsub!(/community (\S+) {/, 'community <hidden> {')
    # 隐藏 SSH 密钥
    cfg.gsub!(/(ssh-(rsa|dsa|ecdsa|ecdsa-sk|ed25519|ed25519-sk) )".*; ## SECRET-DATA/, '<secret removed>')
    # 隐藏加密的密码
    cfg.gsub!(/ "\$\d\$\S+; ## SECRET-DATA/, ' <secret removed>;')
    cfg
  end

  # 处理 show version 命令输出
  cmd 'show version' do |cfg|
    @model = Regexp.last_match(1) if cfg =~ /^Model: (\S+)/
    comment cfg
  end

  # 后处理：根据设备型号执行特定命令
  post do
    out = String.new
    case @model
    when 'mx960'
      # MX960 设备：获取机箱结构可达性信息
      out << cmd('show chassis fabric reachability') { |cfg| comment cfg }
    when /^(ex22|ex3[34]|ex4|ex8|qfx)/
      # EX 和 QFX 系列：获取虚拟机箱信息
      out << cmd('show virtual-chassis') { |cfg| comment cfg }
    when /^srx/
      # SRX 系列：获取机箱集群状态
      out << cmd('show chassis cluster status') do |cfg|
        cfg.lines.count <= 1 && cfg.include?("error:") ? String.new : comment(cfg)
      end
    end
    out
  end

  # 获取机箱硬件信息
  cmd('show chassis hardware') { |cfg| comment cfg }
  # 获取系统许可证信息
  cmd('show system license') do |cfg|
    # 隐藏 FIB 和 RIB 规模信息
    cfg.gsub!(/  fib-scale\s+(\d+)/, '  fib-scale                       <count>')
    cfg.gsub!(/  rib-scale\s+(\d+)/, '  rib-scale                       <count>')
    comment cfg
  end
  # 获取系统许可证密钥
  cmd('show system license keys') { |cfg| comment cfg }

  # 获取配置（省略默认值）
  cmd 'show configuration | display omit'

  # Telnet 连接配置
  cfg :telnet do
    username(/^login:/)
    password(/^Password:/)
  end

  # SSH 连接配置
  cfg :ssh do
    exec true # 不运行 shell，在 exec 通道中运行每个命令
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 设置 CLI 屏幕长度和宽度
    post_login 'set cli screen-length 0'
    post_login 'set cli screen-width 0'
    # 退出命令
    pre_logout 'exit'
  end
end
