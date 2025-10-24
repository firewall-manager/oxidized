# Motorola RFS 设备模型
# 支持 Motorola RFS/Extreme WM 网络设备的配置备份
class Mtrlrfs < Oxidized::Model
  using Refinements

  # Motorola RFS/Extreme WM

  # 提示符正则表达式：匹配 Motorola RFS 设备提示符
  prompt /^([\w.@-]+\*?[#>])\s?$/
  # 注释字符：Motorola RFS 使用井号作为注释
  comment  '# '

  # 处理所有命令的输出，清理格式
  cmd :all do |cfg|
    # xos inserts leading \r characters and other trailing white space.
    # this deletes extraneous \r and trailing white space.
    cfg.each_line.to_a[1..-2].map { |line| line.delete("\r").rstrip }.join("\n") + "\n"
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理许可证信息
  cmd 'show licenses' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config'

  # Telnet 连接配置
  cfg :telnet do
    username /^login:/
    password /^\r*password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    pre_logout do
      send "exit\n"
      send "n\n"
    end
  end
end
