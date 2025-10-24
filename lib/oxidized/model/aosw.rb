# AOSW 设备模型
# 支持 AOSW Aruba 无线、IAP、Instant Controller 和 Mobility Access 交换机
# 用于 Alcatel OAW-4750 WLAN 控制器
# 也支持 Dell 控制器
class AOSW < Oxidized::Model
  using Refinements

  # HPE Aruba 交换机应使用不同的模型，因为软件基于 HP Procurve 系列

  # IAP & Instant Controller 支持已通过 115、205、215 & 325 运行 6.4.4.8-4.2.4.5_57965 测试
  # Mobility Access 交换机支持已通过 S2500-48P & S2500-24P 运行 7.4.1.4_54199 和 S2500-24P 运行 7.4.1.7_57823 测试
  # 连接到 Instant Controller 的所有 IAP 将具有相同的配置输出。只需要监控控制器。

  # 注释字符：AOSW 使用井号作为注释
  comment '# '
  # 提示符正则表达式：匹配 AOSW 设备提示符
  # 参见 /spec/model/aosw_spec.rb 获取提示符示例
  prompt /^\(?[\w:.@-]+\)? ?[*^]?(\[[\w\/]+\] ?)?[#>] ?$/

  # 忽略回车符 - 也用于提示符
  expect "\r" do |data, re|
    data.gsub re, ''
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏密钥
    cfg.gsub!(/secret (\S+)\s?$/, 'secret <secret removed>')
    # 隐藏启用密钥
    cfg.gsub!(/enable secret (\S+)\s?$/, 'enable secret <secret removed>')
    # 隐藏预共享密钥
    cfg.gsub!(/PRE-SHARE (\S+)\s?$/, 'PRE-SHARE <secret removed>')
    # 隐藏 IPSec 密钥
    cfg.gsub!(/ipsec (\S+)\s?$/, 'ipsec <secret removed>')
    # 隐藏社区字符串
    cfg.gsub!(/community (\S+)\s?$/, 'community <secret removed>')
    # 隐藏 SHA 密钥
    cfg.gsub!(/ sha (\S+)/, ' sha <secret removed>')
    # 隐藏 DES 密钥
    cfg.gsub!(/ des (\S+)/, ' des <secret removed>')
    # 隐藏移动管理器用户密码
    cfg.gsub!(/mobility-manager (\S+) user (\S+) (\S+)/, 'mobility-manager \1 user \2 <secret removed>')
    # 隐藏管理用户密码（MAS & 无线控制器）
    cfg.gsub!(/mgmt-user (\S+) (root|guest-provisioning|network-operations|read-only|location-api-mgmt) (\S+)\s?$/, 'mgmt-user \1 \2 <secret removed>')
    # 隐藏管理用户密码（IAP）
    cfg.gsub!(/mgmt-user (\S+) (\S+)( (read-only|guest-mgmt))?\s?$/, 'mgmt-user \1 <secret removed> \3')
    # MAS 格式：mgmt-user <username> <accesslevel> <password hash>
    # IAP 格式（root 用户）：mgmt-user <username> <password hash>
    # IAP 格式：mgmt-user <username> <password hash> <access level>
    # 隐藏密钥
    cfg.gsub!(/key (\S+)\s?$/, 'key <secret removed>')
    # 隐藏 VRRP 密码短语
    cfg.gsub!(/vrrp-passphrase (\S+)\s?$/, 'vrrp-passphrase <secret removed>')
    # 隐藏 WPA 密码短语
    cfg.gsub!(/wpa-passphrase (\S+)\s?$/, 'wpa-passphrase <secret removed>')
    # 隐藏备份密码
    cfg.gsub!(/bkup-passwords (\S+)\s?$/, 'bkup-passwords <secret removed>')
    # 隐藏 AP 控制台密码
    cfg.gsub!(/ap-console-password (\S+)\s?$/, 'ap-console-password <secret removed>')
    # 隐藏虚拟控制器密钥
    cfg.gsub!(/virtual-controller-key (\S+)\s?$/, 'virtual-controller-key <secret removed>')
    cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    # 过滤掉运行时间和重启信息
    cfg = cfg.each_line.reject { |line| line.match(/(Switch|AP) uptime/i) || line.match(/Reboot Time and Cause/i) }
    rstrip_cfg comment cfg.join
  end

  # 处理库存信息
  cmd 'show inventory' do |cfg|
    # 不显示不支持设备的库存信息（IAP 和 MAS）
    cfg = "" if cfg =~ /(Invalid input detected at '\^' marker|Parse error)/
    rstrip_cfg clean cfg
  end

  # 处理插槽信息
  cmd 'show slots' do |cfg|
    # 不显示不支持设备的插槽信息（IAP 和 MAS）
    cfg = "" if cfg =~ /(Invalid input detected at '\^' marker|Parse error)/
    rstrip_cfg comment cfg
  end

  # 处理许可证信息
  cmd 'show license' do |cfg|
    # 不显示不支持设备的许可证信息（IAP 和 MAS）
    cfg = "" if cfg =~ /(Invalid input detected at '\^' marker|Parse error)/
    rstrip_cfg comment cfg
  end

  # 处理许可证密码短语
  cmd 'show license passphrase' do |cfg|
    # 不显示不支持设备的许可证密码短语（IAP 和 MAS）
    cfg = "" if cfg.match /(Invalid input detected at '\^' marker|Parse error)/
    rstrip_cfg comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    out = []
    cfg.each_line do |line|
      # 跳过控制器配置行
      next if line =~ /^controller config \d+$/
      # 跳过构建配置行
      next if line =~ /^Building Configuration/

      out << line.strip
    end
    out = out.join "\n"
    out << "\n"
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^User:\s*/
    password /^Password:\s*/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        # 启用特权模式
        send "enable\n"
        cmd vars(:enable)
      end
    end
    # 禁用分页器
    post_login 'no paging'
    # 禁用加密
    post_login 'encrypt disable'
    # 退出命令
    pre_logout 'exit' if vars :enable
    pre_logout 'exit'
  end

  # 移除配置行尾空白字符
  def rstrip_cfg(cfg)
    out = []
    cfg.each_line do |line|
      out << line.rstrip
    end
    out = out.join "\n"
    out << "\n"
  end

  # 清理配置，移除变化的数据
  def clean(cfg)
    out = []
    cfg.each_line do |line|
      # 移除温度、风扇速度和电压，这些数据每次运行都会变化
      next if line =~ /Output \d Config/i
      next if line =~ /(Tachometers|Temperatures|Voltages)/
      next if line =~ /((Card|CPU) Temperature|Chassis Fan|VMON1[0-9])/
      next if line =~ /[0-9.]{1,6}\s+(RPMS?|m?V|C|W)/i

      out << line.strip
    end
    out = comment out.join "\n"
    out << "\n"
  end
end
