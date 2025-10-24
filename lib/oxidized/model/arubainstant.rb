# Aruba Instant 设备模型
# 支持 Aruba IAP (Instant Access Point) 和 Instant Controller 的配置备份
class ArubaInstant < Oxidized::Model
  using Refinements

  # 注释字符：Aruba Instant 使用井号作为注释
  comment '# '
  # 提示符正则表达式：匹配 Aruba Instant 设备提示符
  prompt(/^ ?[\w:.@-]+[#>] $/)

  # 处理所有命令的输出
  cmd :all do |cfg|
    # 移除命令回显和提示符
    cfg.cut_both
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏 IPSec 密钥
    cfg.gsub!(/ipsec (\S+)$/, 'ipsec <secret removed>')
    # 隐藏 SNMP 社区字符串
    cfg.gsub!(/community (\S+)$/, 'community <secret removed>')
    # 隐藏 SNMP 服务器主机密钥
    cfg.gsub!(/^(snmp-server host [\d.]+ version 2c) \S+ (.*)$/, '\1 <secret removed> \2')
    # 隐藏管理用户密码
    # MAS 格式：mgmt-user <username> <accesslevel> <password hash>
    # IAP 格式（root 用户）：mgmt-user <username> <password hash>
    # IAP 格式：mgmt-user <username> <password hash> <access level>
    cfg.gsub!(/mgmt-user (\S+) (root|guest-provisioning|network-operations|read-only|location-api-mgmt) (\S+)$/, 'mgmt-user \1 \2 <secret removed>') # MAS & Wireless Controler
    cfg.gsub!(/mgmt-user (\S+) (\S+)( (read-only|guest-mgmt))?$/, 'mgmt-user \1 <secret removed> \3') # IAP
    # 隐藏密钥
    cfg.gsub!(/key (\S+)$/, 'key <secret removed>')
    # 隐藏 WPA 密码短语
    cfg.gsub!(/wpa-passphrase (\S+)$/, 'wpa-passphrase <secret removed>')
    # 隐藏备份密码
    cfg.gsub!(/bkup-passwords (\S+)$/, 'bkup-passwords <secret removed>')
    # 隐藏用户密码
    cfg.gsub!(/user (\S+) (\S+) (\S+)$/, 'user \1 <secret removed> \3')
    # 隐藏虚拟控制器密钥
    cfg.gsub!(/virtual-controller-key (\S+)$/, 'virtual-controller-key <secret removed>')
    # 隐藏哈希管理用户密码
    cfg.gsub!(/^(hash-mgmt-user .* password \S+) \S+( usertype .*)?$/, '\1 <secret removed>\2')
    cfg
  end

  # 获取软件版本信息
  cmd 'show version' do |cfg|
    out = ''
    cfg.each_line do |line|
      # 跳过交换机或 AP 运行时间信息
      next if line =~ /^(Switch|AP) uptime is /

      # 跳过重启时间和原因信息
      next if line =~ /^Reboot Time and Cause/

      out += line
    end
    comment out
  end

  # 获取序列号信息
  cmd 'show activate status' do |cfg|
    out = ''
    cfg.each_line do |line|
      # 跳过激活信息
      next if line =~ /^Activate /

      # 跳过配置间隔信息
      next if line =~ /^Provision interval/

      # 跳过云激活密钥信息
      next if line =~ /^Cloud Activation Key/

      out += line
    end
    comment out + "\n"
  end

  # 获取受控 WLAN-AP 信息
  cmd 'show aps' do |cfg|
    out = ''
    cfg.each_line do |line|
      out += if line.match?(/^Name/)
               # 处理标题行
               line.sub(/^(Name +IP Address +).*(Type +IPv6 Address +).*(Serial #).*$/, '\1\2\3')
             else
               # 处理数据行
               line.sub(/^(\S+ +\S+ +)(?:\S+ +){3}(\S+ +\S+ +)(?:\S+ +){2}(\S+) +.*$/, '\1\2\3')
             end
    end
    comment out + "\n"
  end

  # 获取运行配置（不加密）
  cmd 'show running-config no-encrypt'

  # Telnet 连接配置
  cfg :telnet do
    username(/^User:\s*/)
    password(/^Password:\s*/)
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        # 启用特权模式
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    # 退出命令
    pre_logout 'exit' if vars :enable
    pre_logout 'exit'
  end
end
