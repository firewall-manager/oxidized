# Cisco IOS 设备模型
# 支持 Cisco IOS 系列设备的配置备份
class IOS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配设备提示符
  prompt /^([\w.@()-]+[#>]\s?)$/
  # 注释字符：Cisco IOS 使用感叹号作为注释
  comment  '! '

  # 处理分页器的示例
  # expect /^\s--More--\s+.*$/ do |data, re|
  #  send ' '
  #  data.sub re, ''
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
    # 清除某些设备上不工作的命令的错误信息
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.cut_both
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # SNMP 社区字符串
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    # SNMP 主机配置
    cfg.gsub! /^(snmp-server host \S+( vrf \S+)?( informs?)?( version (1|2c))?) +\S+( .*)?$*/, '\\1 <secret hidden>\\6'
    # 用户名密码
    cfg.gsub! /^(username .+ (password|secret) \d) .+/, '\\1 <secret hidden>'
    # 启用密码
    cfg.gsub! /^(enable (password|secret)( level \d+)? \d) .+/, '\\1 <secret hidden>'
    # 通用密码和密钥
    cfg.gsub! /^( +(?:password|secret)) (?:\d )?\S+/, '\\1 <secret hidden>'
    # WPA-PSK 密钥
    cfg.gsub! /^(.*wpa-psk ascii \d) (\S+)/, '\\1 <secret hidden>'
    # 类型 7 密钥
    cfg.gsub! /^(.*key 7) (\d.+)/, '\\1 <secret hidden>'
    # TACACS 服务器密钥
    cfg.gsub! /^(tacacs-server (.+ )?key) .+/, '\\1 <secret hidden>'
    # ISAKMP 密钥
    cfg.gsub! /^(crypto isakmp key) (\S+) (.*)/, '\\1 <secret hidden> \\3'
    # OSPF 消息摘要密钥
    cfg.gsub! /^( +ip ospf message-digest-key \d+ md5) .+/, '\\1 <secret hidden>'
    # OSPF 认证密钥
    cfg.gsub! /^( +ip ospf authentication-key) .+/, '\\1 <secret hidden>'
    # BGP 邻居密码
    cfg.gsub! /^( +neighbor \S+ password) .+/, '\\1 <secret hidden>'
    # VRRP 认证文本
    cfg.gsub! /^( +vrrp \d+ authentication text) .+/, '\\1 <secret hidden>'
    # HSRP 认证
    cfg.gsub! /^( +standby \d+ authentication) .{1,8}$/, '\\1 <secret hidden>'
    # HSRP MD5 密钥字符串
    cfg.gsub! /^( +standby \d+ authentication md5 key-string) .+?( timeout \d+)?$/, '\\1 <secret hidden> \\2'
    # 通用密钥字符串
    cfg.gsub! /^( +key-string) .+/, '\\1 <secret hidden>'
    # TACACS/RADIUS 服务器密钥
    cfg.gsub! /^((tacacs|radius) server [^\n]+\n( +[^\n]+\n)* +key) [^\n]+$/m, '\1 <secret hidden>'
    # PPP CHAP/PAP 密码
    cfg.gsub! /^( +ppp (chap|pap) password \d) .+/, '\\1 <secret hidden>'
    # WPA PSK 设置密钥
    cfg.gsub! /^( +security wpa psk set-key (?:ascii|hex) \d) (.*)$/, '\\1 <secret hidden>'
    # 802.1X 用户名密码
    cfg.gsub! /^( +dot1x username \S+ password \d) (.*)$/, '\\1 <secret hidden>'
    # 管理用户密码和密钥
    cfg.gsub! /^( +mgmtuser username \S+ password \d) (.*) (secret \d) (.*)$/, '\\1 <secret hidden> \\3 <secret hidden>'
    # 客户端服务器密钥
    cfg.gsub! /^( +client \S+ server-key \d) (.*)$/, '\\1 <secret hidden>'
    # 域密码
    cfg.gsub! /^( +domain-password) \S+ ?(.*)/, '\\1 <secret hidden> \\2'
    # 预共享密钥
    cfg.gsub! /^( +pre-shared-key).*/, '\\1 <configuration removed>'
    # 服务器密钥
    cfg.gsub! /^(.*server-key(?: \d)?) \S+/, '\\1 <secret hidden>'
    cfg
  end

  # 处理 show version 命令输出，提取设备信息
  cmd 'show version' do |cfg|
    comments = []
    comments << cfg.lines.first
    lines = cfg.lines
    lines.each_with_index do |line, i|
      slave = ''
      slaveslot = ''

      # 检查从设备槽位
      if line =~ /^Slave in slot (\d+) is running/
        slave = " Slave:"
        slaveslot = ", slot #{Regexp.last_match(1)}"
      end

      # 提取编译信息
      comments << "Image:#{slave} Compiled: #{Regexp.last_match(1)}" if line =~ /^Compiled (.*)$/

      # 提取 IOS 软件信息
      if line =~ /^(?:Cisco )?IOS .* Software,? \(([A-Za-z0-9_-]*)\), .*Version\s+(.*)$/
        comments << "Image:#{slave} Software: #{Regexp.last_match(1)}, #{Regexp.last_match(2)}"
      end

      # 提取 ROM Bootstrap 信息
      if line =~ /^ROM: (IOS \S+ )?(System )?Bootstrap.*(Version.*)$/
        comments << "ROM Bootstrap: #{Regexp.last_match(3)}"
      end

      # 提取 BOOTFLASH 信息
      comments << "BOOTFLASH: #{Regexp.last_match(1)}" if line =~ /^BOOTFLASH: .*(Version.*)$/

      # 提取 NVRAM 内存信息
      comments << "Memory: nvram #{Regexp.last_match(1)}" if line =~ /^(\d+[kK]) bytes of (non-volatile|NVRAM)/

      # 提取 Flash 内存信息
      if line =~ /^(\d+[kK]) bytes of (flash memory|flash internal|processor board System flash|ATA CompactFlash)/i
        comments << "Memory: flash #{Regexp.last_match(1)}"
      end

      # 提取 PCMCIA 内存信息
      if line =~ /^(\d+[kK]) bytes of (Flash|ATA)?.*PCMCIA .*(slot|disk) ?(\d)/i
        comments << "Memory: pcmcia #{Regexp.last_match(2)} #{Regexp.last_match(3)}#{Regexp.last_match(4)} #{Regexp.last_match(1)}"
      end

      # 提取处理器和内存信息
      if line =~ /(\S+(?:\sseries)?)\s+(?:\(([\S ]+)\)\s+processor|\(revision[^)]+\)).*\s+with (\S+k) bytes/i
        sproc = Regexp.last_match(1)
        cpu = Regexp.last_match(2)
        mem = Regexp.last_match(3)
        cpuxtra = ''
        comments << "Chassis type:#{slave} #{sproc}"
        comments << "Memory:#{slave} main #{mem}"
        # 检查接下来两行的 CPU 信息
        comments << "Processor ID: #{Regexp.last_match(1)}" if cfg.lines[i + 1] =~ /processor board id (\S+)/i
        if cfg.lines[i + 2] =~ /(cpu at |processor: |#{cpu} processor,)/i
          # 将 implementation 改为 impl 并添加逗号前缀
          cpuxtra = cfg.lines[i + 2].gsub("implementation", 'impl').gsub(/^/, ', ').chomp
        end
        comments << "CPU:#{slave} #{cpu}#{cpuxtra}#{slaveslot}"
      end

      # 提取系统镜像文件信息
      comments << "Image: #{Regexp.last_match(1)}" if line =~ /^System image file is "([^"]*)"$/
    end
    comments << "\n"
    comment comments.join "\n"
  end

  # 处理 VTP 状态信息
  cmd 'show vtp status' do |cfg|
    cfg.gsub! /^$\n/, ''
    cfg.gsub! /Configuration last modified by.*\n/, ''
    cfg.gsub! /^/, 'VTP: ' unless cfg.empty?
    comment "#{cfg}\n"
  end

  # 处理设备清单信息
  cmd 'show inventory' do |cfg|
    comment cfg
  end

  # 后处理：获取运行配置
  post do
    cmd_line = 'show running-config'
    cmd_line += ' view full' if vars(:ios_rbac)
    cmd cmd_line do |cfg|
      # 移除前3行（通常是头部信息）
      cfg = cfg.each_line.to_a[3..-1]
      # 移除 NTP 时钟周期信息
      cfg = cfg.reject { |line| line.match /^ntp clock-period / }.join
      # 移除配置变更时间戳（除非包含用户信息）
      cfg = cfg.each_line.reject do |line|
        line.match /^! (Last|No) configuration change (at|since).*/ unless line =~ /\d+\sby\s\S+$/
      end.join
      # 移除当前配置头部
      cfg.gsub! /^Current configuration : [^\n]*\n/, ''
      # 移除 MPLS TE 带宽配置
      cfg.gsub! /^ tunnel mpls traffic-eng bandwidth[^\n]*\n*(
                    (?: [^\n]*\n*)*
                    tunnel mpls traffic-eng auto-bw)/mx, '\1'
      # 移除自定义 SNMP OID 的值
      cfg.gsub! /^(\s+expression) \d+$/, '\\1 <value removed>'
      cfg
    end
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/i
    password /^Password:/i
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 处理额外密码的首选方式
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    # 设置终端长度和宽度
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    # 退出命令
    pre_logout 'exit'
  end
end
