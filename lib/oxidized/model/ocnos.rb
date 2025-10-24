# Edgecore OcNOS 设备模型
# 支持 Edgecore OcNOS 网络设备的配置备份
class OcNOS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 OcNOS 设备提示符
  prompt /([\w.@-]+[#>]\s?)$/
  # 注释字符：OcNOS 使用井号作为注释
  comment '# '

  # SSH 连接配置
  cfg :ssh do
    post_login 'terminal length 0'
    pre_logout do
      send "disable\r"
      send "logout\r"
    end
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.lines.to_a[1..-2].join
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理系统 FRU 信息
  cmd 'show system fru' do |cfg|
    comment cfg
  end

  # 处理系统信息板卡信息
  cmd 'show system-information board-info' do |cfg|
    comment cfg
  end

  # 处理转发配置文件限制信息
  cmd 'show forwarding profile limit' do |cfg|
    comment cfg
  end

  # 处理许可证信息
  cmd 'show license' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg
  end
end
