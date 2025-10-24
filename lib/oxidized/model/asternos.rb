# AsterNOS 设备模型
# 支持 AsterNOS 网络设备的配置备份
class AsterNOS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 AsterNOS 设备提示符
  prompt /^[^$]+\$/
  # 注释字符：AsterNOS 使用井号作为注释
  comment '# '

  # 处理所有命令的输出
  cmd :all do |cfg|
    # 移除第一行和最后一行
    cfg.each_line.to_a[1..-2].join
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    # 可以提取设备型号信息
    # @model = Regexp.last_match(1) if cfg =~ /^Model: (\S+)/
    comment cfg
  end

  # 获取所有运行配置
  cmd "show runningconfiguration all"

  # SSH 连接配置
  cfg :ssh do
    # 在 exec 通道中运行命令（可选）
    # exec true
    # 退出命令
    pre_logout 'exit'
  end
end
