# Fujitsu OneFinity 设备模型
# 支持 Fujitsu 1finity 网络设备的配置备份
class OneFinity < Oxidized::Model
  using Refinements

  # Fujitsu 1finity

  # 提示符正则表达式：匹配 OneFinity 设备提示符
  prompt /(\r?[\w.@_()-]+>\s?)$/

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.each_line.to_a[1..-3].join
  end

  # 处理配置信息，使用 display set 格式并禁用分页器
  cmd 'show configuration | display set | nomore'

  # SSH 连接配置
  cfg :ssh do
    pre_logout 'exit'
    exec true
  end
end
