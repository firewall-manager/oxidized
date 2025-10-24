# Nokia SR OS 设备模型
# 支持 Nokia SR OS (TiMOS) 的配置备份
# 用于 7705 SAR、7210 SAS、7450 ESS、7750 SR、7950 XRS 和 NSP
class SROS < Oxidized::Model
  using Refinements

  #
  # Nokia SR OS (TiMOS) (formerly TiMetra, Alcatel, Alcatel-Lucent).
  # Used in 7705 SAR, 7210 SAS, 7450 ESS, 7750 SR, 7950 XRS, and NSP.
  #

  # 注释字符：SROS 使用井号作为注释
  comment '# '

  # 提示符正则表达式：匹配 SROS 设备提示符
  prompt /^([-\w.:>*]+\s?[#>]\s?)$/

  # 处理所有命令的输出
  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    cfg.gsub! /# Finished .*/, ''
    cfg.gsub! /# Generated .*/, ''
    cfg.delete! "\r"
    new_cfg << cfg.cut_both
  end

  # 显示启动选项文件
  # Show the boot options file.
  cmd 'show bof' do |cfg|
    comment cfg
  end

  # 显示系统信息
  # Show the system information.
  cmd 'show system information' do |cfg|
    # 移除运行时间信息
    # Strip uptime.
    cfg.gsub! /^System Up Time.*$/, ''
    comment cfg
  end

  # 显示卡状态
  # Show the card state.
  cmd 'show card state' do |cfg|
    comment cfg
  end

  # 显示机箱信息
  # Show the chassis information.
  cmd 'show chassis' do |cfg|
    comment cfg.lines.to_a[0..25].reject { |line| line.match /state|Time|Temperature|Status/ }.join
  end

  # 显示启动日志
  # Show the boot log.
  cmd 'file type bootlog.txt' do |cfg|
    cfg.gsub! /[\b][\b][\b]/, "\n"
    comment cfg
  end

  # 显示运行调试配置
  # Show the running debug configuration.
  cmd 'show debug' do |cfg|
    comment cfg
  end

  # 显示保存的调试配置（admin debug-save）
  # Show the saved debug configuration (admin debug-save).
  cmd 'file type config.dbg' do |cfg|
    comment cfg
  end

  # 显示运行持久索引
  # Show the running persistent indices.
  cmd "admin display-config index\n" do |cfg|
    comment cfg
  end

  # 显示运行配置
  # Show the running configuration.
  cmd "admin display-config\n" do |cfg|
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Login: /
    password /^Password: /
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login 'environment no more'
    pre_logout 'logout'
  end
end
