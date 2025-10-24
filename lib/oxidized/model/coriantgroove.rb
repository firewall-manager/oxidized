# Coriant Groove 设备模型
# 支持 Coriant Groove 网络设备的配置备份
class CoriantGroove < Oxidized::Model
  using Refinements

  # 注释字符：Coriant Groove 使用井号作为注释
  comment '# '

  # 提示符正则表达式：匹配 Coriant Groove 设备提示符
  prompt /^(\w+@.*>\s*)$/

  # 处理所有命令的输出，移除首尾行并清理回车符
  cmd :all do |cfg|
    cfg.each_line.to_a[1..-3].map { |line| line.delete("\r").rstrip }.join("\n") + "\n"
  end

  # 处理设备清单信息
  cmd 'show inventory' do |cfg|
    comment cfg.cut_tail
  end

  # 处理软件加载信息
  cmd 'show softwareload' do |cfg|
    comment cfg.cut_tail
  end

  # 处理配置信息，使用 display commands 格式
  cmd 'show config | display commands' do |cfg|
    cfg.cut_head
  end

  # SSH 连接配置
  cfg :ssh do
    post_login 'set -f cli-config cli-columns 4000'
    pre_logout 'quit -f'
  end
end
