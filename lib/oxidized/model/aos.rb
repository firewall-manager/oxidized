# AOS 设备模型
# 支持 Alcatel-Lucent 操作系统（用于 OmniSwitch）的配置备份
class AOS < Oxidized::Model
  using Refinements

  # Alcatel-Lucent Operating System
  # used in OmniSwitch

  # 注释字符：AOS 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理系统信息，提取描述信息
  cmd 'show system' do |cfg|
    cfg = cfg.each_line.find { |line| line.match 'Description' }
    comment cfg.to_s.strip
  end

  # 处理机箱信息
  cmd 'show chassis' do |cfg|
    comment cfg
  end

  # 处理硬件信息
  cmd 'show hardware info' do |cfg|
    comment cfg
  end

  # 处理许可证信息
  cmd 'show license info' do |cfg|
    comment cfg
  end

  # 处理许可证文件
  cmd 'show license file' do |cfg|
    comment cfg
  end

  # 处理配置快照
  cmd 'show configuration snapshot' do |cfg|
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^login : /
    password /^password : /
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    pre_logout 'exit'
  end
end
