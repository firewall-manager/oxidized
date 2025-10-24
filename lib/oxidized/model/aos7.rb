# AOS7 设备模型
# 支持 Alcatel-Lucent 操作系统版本 7（基于 Linux，用于 OmniSwitch 6900/10k）的配置备份
class AOS7 < Oxidized::Model
  using Refinements

  # Alcatel-Lucent Operating System Version 7 (Linux based)
  # used in OmniSwitch 6900/10k

  # 提示符正则表达式：匹配 AOS7 设备提示符
  prompt /^([\w.@-]+ ?[#>]\s?)$/

  # 注释字符：AOS7 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出
  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    new_cfg << cfg.cut_both
  end

  # 处理系统信息，提取描述信息
  cmd 'show system' do |cfg|
    cfg = cfg.each_line.find { |line| line.match 'Description' }
    comment cfg.to_s.strip + "\n"
  end

  # 处理机箱信息，检查虚拟机箱存在性
  cmd 'show chassis' do |cfg|
    # check for virtual chassis existence
    @slave_vcids = cfg.scan(/Chassis ID (\d+) \(Slave\)/).flatten
    @master_vcid = Regexp.last_match(1) if cfg =~ /Chassis ID (\d+) \(Master\)/
    comment cfg
  end

  # 处理硬件信息，移除命令运行缓慢时的额外行
  cmd 'show hardware-info' do |cfg|
    # Remove extra lines occuring when the command runs slow
    cfg.gsub! /^Please wait...\n/, ''
    cfg.gsub! /^\n\n\n/, "\n\n"
    comment cfg
  end

  # 处理运行目录，移除命令运行缓慢时的额外行
  cmd 'show running-directory' do |cfg|
    # Remove extra lines occuring when the command runs slow
    cfg.gsub! /^Please wait...\n/, ''
    cfg.gsub! /^\n\n/, "\n"
    comment cfg
  end

  # 处理配置快照，移除命令运行缓慢时的额外行
  cmd 'show configuration snapshot' do |cfg|
    # Remove extra lines occuring when the command runs slow
    cfg.gsub! /^Please wait...\n/, ''
    cfg.gsub! /^\n\n/, "\n"
    cfg
  end

  # 预处理：处理虚拟机箱配置
  pre do
    cfg = []
    if @master_vcid
      # add slave VC boot config as comment
      @slave_vcids.each do |id|
        cfg << comment("vc_boot.cfg for slave chassis #{id}")
        cfg << comment(cmd("show configuration vcm-snapshot chassis-id #{id}"))
      end
      cfg << cmd("show configuration vcm-snapshot chassis-id #{@master_vcid}")
    end
    cfg.join "\n"
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^([\w -])*login: /
    password /^Password\s?: /
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    pre_logout 'exit'
  end
end
