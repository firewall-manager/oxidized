# Fortinet WLC 设备模型
# 支持 Fortinet 无线控制器的配置备份
class FortiWLC < Oxidized::Model
  using Refinements

  # 注释字符：FortiWLC 使用井号作为注释
  comment '# '

  # 处理所有命令的输出
  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    # 隐藏配置文件版本信息
    new_cfg << cfg.each_line.to_a[1..-2].map { |line| line.gsub(/(conf_file_ver=)(.*)/, '\1<stripped>\3') }.join
  end

  # 提示符正则表达式：匹配 FortiWLC 设备提示符
  prompt /^([-\w.\/:?\[\]()]+[#>]\s?)$/

  # 处理控制器信息
  cmd 'show controller' do |cfg|
    comment cfg
  end
  
  # 处理接入点信息
  cmd 'show ap' do |cfg|
    comment cfg
  end
  
  # 处理运行配置
  cmd 'show running-config' do |cfg|
    comment cfg
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 退出命令
    pre_logout "exit\n"
  end
end
