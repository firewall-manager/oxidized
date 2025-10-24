# Telco 设备模型
# 支持 Telco Systems T-Marc 3306 网络设备的配置备份
class TELCO < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 Telco 设备提示符
  prompt /^(\r?[\w.@_()-]+\#\s?)$/
  # 注释字符：Telco 使用感叹号作为注释
  comment '! '

  # 处理所有命令的输出
  cmd :all do |cfg|
    # 移除前两行和最后两行，并删除换行符
    cfg.each_line.to_a[2..-2].join.delete("\n")
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg
  end

  # SSH 和 Telnet 连接配置
  cfg :ssh, :telnet do
    # 设置终端长度为 0
    post_login 'terminal length 0'
    # 退出命令
    pre_logout 'exit'
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end
end
