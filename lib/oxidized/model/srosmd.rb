# Nokia SR OS MD 设备模型
# 支持 Nokia SR OS (TiMOS) 的配置备份
# 在模型驱动 CLI 模式下工作
# 用于 7705 SAR、7210 SAS、7450 ESS、7750 SR、7950 XRS 和 NSP
class SROSMD < Oxidized::Model
  using Refinements

  # 注释字符：SROS MD 使用井号作为注释
  comment '# '

  # 提示符正则表达式：匹配 SROS MD 设备提示符
  prompt /^([-\w.@:>*]+\s?[#>]\s?)$/

  # 处理所有命令的输出
  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    # 移除完成信息
    cfg.gsub! /# Finished .*/, ''
    # 移除生成信息
    cfg.gsub! /# Generated .*/, ''
    # 删除回车符
    cfg.delete! "\r"
    new_cfg << cfg.cut_both
  end

  # 显示系统信息
  cmd 'show system information' do |cfg|
    # 移除运行时间信息
    cfg.gsub! /^System Up Time.*\n/, ''
    comment cfg
  end

  # 显示卡状态
  cmd 'show card state' do |cfg|
    comment cfg
  end

  # 显示机箱信息
  cmd 'show chassis' do |cfg|
    # 过滤掉状态、时间、温度和状态信息
    comment cfg.lines.to_a[0..25].reject { |line| line.match /state|Time|Temperature|Status/ }.join
  end

  # 显示启动日志
  cmd 'file show bootlog.txt' do |cfg|
    # 处理退格符
    cfg.gsub! /[\b][\b][\b]/, "\n"
    comment cfg
  end

  # 显示运行调试配置
  cmd 'admin show configuration debug full-context' do |cfg|
    comment cfg
  end

  # 显示保存的调试配置（admin debug-save）
  cmd 'file show config.dbg' do |cfg|
    comment cfg
  end

  # 显示运行持久索引
  cmd 'admin show configuration configure | match persistent-indices post-lines 10000' do |cfg|
    comment cfg
  end

  # 显示启动选项文件
  cmd 'admin show configuration bof full-context' do |cfg|
    cfg
  end

  # 显示运行配置
  cmd 'admin show configuration configure full-context' do |cfg|
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Login: /
    password /^Password: /
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 设置环境分页器关闭
    post_login 'environment more false'
    # 退出命令
    pre_logout 'logout'
  end
end
