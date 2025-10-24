# Trango 设备模型
# 支持 Trango 网络设备的配置备份
# 将 Trangolink sysinfo 输出转换为配置文件
class Trango < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 Trango 设备提示符
  prompt /^#>\s?/
  # 注释字符：Trango 使用井号作为注释
  comment '# '

  # 处理系统信息，转换为配置格式
  cmd 'sysinfo' do |cfg|
    out = []
    comments = []
    cfg.each_line do |line|
      # 处理操作模式
      if line =~ /\[Opmode\] (off|on) \[Default Opmode\] (off|on)/
        out << ("opmode " + Regexp.last_match[1])
        out << ("defaultopmode " + Regexp.last_match[2])
      end
      # 处理发射功率
      out << ("power " + Regexp.last_match[1]) if line =~ /\[Tx Power\] ([-\d]+) dBm/
      # 处理活动信道
      out << ("freq " + Regexp.last_match[1] + ' ' + Regexp.last_match[2]) if line =~ /\[Active Channel\] (\d+) (v|h)/
      # 处理对等方 ID
      out << ("peerid " + Regexp.last_match[1]) if line =~ /\[Peer ID\] ([A-F0-9]+)/
      # 处理单元类型
      out << ("utype " + Regexp.last_match[1]) if line =~ /\[Unit Type\] (\S+)/
      # 处理硬件版本、固件版本、型号、序列号
      if line =~ /\[(Hardware Version|Firmware Version|Model|S\/N)\] (\S+)/
        comments << ('# ' + Regexp.last_match[1] + ': ' + Regexp.last_match[2])
      end
      # 处理备注
      out << ("remarks " + Regexp.last_match[1]) if line =~ /\[Remarks\] (\S+)/
      # 处理 RSSI LED
      out << ("rssiled " + Regexp.last_match[1]) if line =~ /\[RSSI LED\] (on|off)/
      # 处理速度
      speed = Regexp.last_match[1] if line =~ /\[Speed\] (\d+) Mbps/
      # 处理发射 MIR
      out << "mir ".concat(Regexp.last_match[1]) if line =~ /\[Tx MIR\] (\d+) Kbps/
      # 处理自动速率切换
      if line =~ /\[Auto Rate Shift\] (on|off)/
        out << "autorateshift ".concat(Regexp.last_match[1])
        out << "speed #{speed}" if Regexp.last_match[1].eql? 'off'
      end
      # 处理 IP 配置
      next unless line =~ /\[IP\] (\S+) \[Subnet Mask\] (\S+) \[Gateway\] (\S+)/

      out << ("ipconfig " + Regexp.last_match[1] + ' ' +
             Regexp.last_match[2] + ' ' +
             Regexp.last_match[3])
    end
    comments.push(*out).join "\n"
  end

  # Telnet 连接配置
  cfg :telnet do
    password /Password:/
    # 退出命令
    pre_logout 'exit'
  end
end
