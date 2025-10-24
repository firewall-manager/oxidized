# A10 ACOS 设备模型
# 支持 A10 ACOS AX 和 Thunder 系列设备的配置备份
class ACOS < Oxidized::Model
  using Refinements

  # A10 ACOS model for AX and Thunder series

  # 注释字符：ACOS 使用感叹号作为注释
  comment '! '

  # ACOS 提示符根据设备状态变化
  # 提示符正则表达式：匹配 ACOS 设备提示符
  prompt /^([-\w.\/:?\[\]()]+[#>]\s?)$/

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    cfg.gsub!(/community read encrypted (\S+)/, 'community read encrypted <hidden>') # snmp
    cfg.gsub!(/secret encrypted (\S+)/, 'secret encrypted <hidden>') # tacacs-server
    cfg.gsub!(/password encrypted (\S+)/, 'password encrypted <hidden>') # user
    cfg
  end

  # 处理版本信息，移除时间相关动态信息
  cmd 'show version' do |cfg|
    cfg.gsub! /\s(Last configuration saved at).*/, ' \\1 <removed>'
    cfg.gsub! /\s(Memory).*/, ' \\1 <removed>'
    cfg.gsub! /\s(Current time is).*/, ' \\1 <removed>'
    cfg.gsub! /\s(The system has been up).*/, ' \\1 <removed>'
    cfg.gsub! /\s(Hardware: \d+ CPUs\(Stepping \d+\). Single \d+G drive. Free storage is).*/, ' \\1 <removed>'
    comment cfg
  end

  # 处理启动镜像信息
  cmd 'show bootimage' do |cfg|
    comment cfg
  end

  # 处理许可证信息
  cmd 'show license' do |cfg|
    comment cfg
  end

  # 处理所有分区配置，移除时间戳信息
  cmd 'show partition-config all' do |cfg|
    cfg.gsub! /(Current configuration).*/, '\\1 <removed>'
    cfg.gsub! /(Configuration last updated at).*/, '\\1 <removed>'
    cfg.gsub! /(Configuration last saved at).*/, '\\1 <removed>'
    cfg.gsub! /(Configuration last synchronized at).*/, '\\1 <removed>'
    cfg
  end

  # 处理所有分区的运行配置，移除时间戳信息
  cmd 'show running-config all-partitions' do |cfg|
    cfg.gsub! /(Current configuration).*/, '\\1 <removed>'
    cfg.gsub! /(Configuration last updated at).*/, '\\1 <removed>'
    cfg.gsub! /(Configuration last saved at).*/, '\\1 <removed>'
    cfg.gsub! /(Configuration last synchronized at).*/, '\\1 <removed>'
    cfg
  end

  # 处理所有分区的 aflex 脚本信息
  cmd 'show aflex all-partitions' do |cfg|
    comment cfg
  end

  # 解析 aflex 脚本信息，只考虑通过语法检查的脚本
  cmd 'show aflex all-partitions' do |cfg|
    @partitions_aflex = cfg.lines.each_with_object({}) do |l, h|
      h[Regexp.last_match(1)] = [] if l =~ /partition: (.+)/
      # only consider scripts that have passed syntax check
      h[h.keys.last] << Regexp.last_match(1) if l =~ /^([\w-]+) +Check/
    end
    ''
  end

  # 处理所有命令的输出
  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    new_cfg << cfg.cut_both
  end

  # 预处理：生成 aflex 脚本内容
  pre do
    unless @partitions_aflex.empty?
      out = []
      @partitions_aflex.each do |partition, arules|
        out << "! partition: #{partition}"
        arules.each do |name|
          cmd("show aflex #{name} partition #{partition}") do |cfg|
            content = cfg.split("Content:").last.strip
            out << "aflex create #{name}"
            out << content
            out << ".\n"
          end
        end
      end
      out.join "\n"
    end
  end

  # Telnet 连接配置
  cfg :telnet do
    username  /login:/
    password  /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 处理额外密码的首选方式
    post_login do
      pw = vars(:enable)
      pw ||= ""
      send "enable\r\n"
      cmd pw
    end
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    pre_logout "exit\nexit\nY\r\n"
  end
end
