# Ubiquiti UniFi AP 设备模型
# 支持 Ubiquiti UniFi AP 6.x 版本的配置备份
# 也应该适用于 UniFi 交换机和 airOS，也许可以合并它们
# 由于它依赖于 exec 通道，因为交互式会话不会捕获所有 system.cfg 输出，
# 所以不能在此模型中使用 telnet
class Unifiap < Oxidized::Model
  using Refinements

  # 有时有一个方便的信息命令可以总结一些设备属性，
  # 但在 exec 模式下似乎不可用。所以我们尝试通过从各种地方提取信息来构建类似的列表。
  # AirOS 没有其中一些文件，所以可能必须回退到其他命令或位置。

  # 首先获取板卡型号
  cmd 'head -4 /etc/board.info' do |cfg|
    @model = Regexp.last_match(1) if cfg =~ /board\.name=(\S+)/i
    ""
  end

  # 获取版本信息
  cmd 'cat /etc/version' do |cfg|
    @version = Regexp.last_match(1) if cfg =~ /(\S+)$/i
    ""
  end

  # 获取 MAC 地址
  cmd 'ifconfig eth0' do |cfg|
    @mac = Regexp.last_match(1) if cfg =~ /eth0\s+Link encap:Ethernet\s+HWaddr\s+(\w+:\w+:\w+:\w+:\w+:\w+)/i
    ""
  end

  # 尝试从 /etc/hosts 获取 IP 和主机名
  cmd 'cat /etc/hosts' do |cfg|
    cfg = cfg.split("\n").reject do |line|
      line[/^\s*(127|0000:0000:0000:0000:0000:0000:0000:0001|0:0:0:0:0:0:0:1|::1)/]
    end
    cfg.select do |line|
      if (match = line.match(/(\d+\.\d+\.\d+\.\d+)\s+(\S+)/))
        @ip, @hostname = match.captures
      end
    end
    ""
  end

  # 检查是否成功从 /etc/hosts 获取信息。如果没有，则尝试使用 ifconfig 和 /tmp/system.cfg
  cmd 'echo' do
    unless @ip
      cmd 'ifconfig br0' do |cfg|
        @ip = Regexp.last_match(1) if cfg =~ /inet addr:\s*(\d+\.\d+\.\d+\.\d+)/i
      end

      unless @ip
        cmd 'ifconfig eth0' do |cfg|
          @ip = Regexp.last_match(1) if cfg =~ /inet addr:\s*(\d+\.\d+\.\d+\.\d+)/i
        end
      end
    end

    unless @hostname
      cmd 'cat /tmp/system.cfg' do |cfg|
        @hostname = Regexp.last_match(1) if cfg =~ /resolv.host.1.name=(\S+)/i
      end
    end
    ""
  end

  # 检查 ntpclient 是否正在运行
  cmd 'ps wwww' do |cfg|
    @ntpserver = Regexp.last_match(1) if cfg =~ /bin\/ntpclient.+-h\s*(\S+)/i
    ""
  end

  # 如果是 UniFi 设备，可能有 NTP 健康指示
  # 如果 Ubiquiti 在其他地方放置这些状态文件，请在此处添加它们
  cmd '[ -e /tmp/run/ntp.ready ] || [ -e /var/run/ntp.ready ] && echo "File(s) exist(s)" || echo "No such file"' do |cfg|
    if cfg =~ /No such file/i
      if @ntpserver
        # 好的，现在尝试从 ntpclient 的输出中获取偏差
        cmd "ntpclient -d -n -c 2 -i0 -h #{@ntpserver}" do |ntp_out|
          @skew = ntpskew(ntp_out)
        end
        @sync = !@skew.nil? && @skew.to_f.abs < 1e6 ? "Synchronized" : "FAIL"
      end
    else
      @ntpserver = true
      @sync = "Synchronized"
    end
    ""
  end

  # 现在可以将所有信息显示为横幅
  cmd 'echo' do
    out = []
    out << "*************************"
    out << "Model:       #{@model}"
    out << "Version:     #{@version}"
    out << "MAC Address: #{@mac}"
    out << "IP Address:  #{@ip}"
    out << "Hostname:    #{@hostname}"
    out << "NTP:         #{@sync}" if @ntpserver
    out << "*************************"
    comment out.join("\n") + "\n"
  end

  # 接下来是板卡信息
  cmd 'cat /etc/board.info' do |cfg|
    cfg = "#\n# Board Info:\n#\n" + cfg
    comment cfg
  end

  # 最后是系统配置
  cmd 'cat /tmp/system.cfg' do |cfg|
    cfg = "#\n# System Config:\n#\n" + cfg
    cfg + "\n"
  end

  # 处理敏感信息，隐藏密码
  cmd :secret do |cfg|
    cfg.gsub! /^((?:users|snmp\.(?:user|community))\.\d+\.password)=.+/, "# \\1=<hidden>"
    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    # 不运行 shell，在 exec 通道中运行每个命令
    exec true
  end

  # NTP 偏差：从 ntpclient 输出返回以微秒为单位的偏差
  def ntpskew(cfg)
    index = skew = nil

    cfg.each_line do |line|
      # 查找统计行之前的标题，并找到哪个数字是偏差
      if line.match(/^\s*[a-z]+\s+[a-z]+\s+[a-z]+\s+[a-z]+/i)
        words = line.split
        index = words.map(&:downcase).index("skew")
      end
      # 现在查找单个统计行并获取偏差
      if !index.nil? && line.match(/^\s*[\d.]+\s+[\d.]+\s+[\d.]+\s+[\d.]+/)
        numbers = line.split
        skew = numbers[index]
      end
    end
    skew
  end
end
