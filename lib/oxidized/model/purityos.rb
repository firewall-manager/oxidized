# Pure Storage Purity OS 设备模型
# 支持 Pure Storage Purity OS 存储系统的配置备份
class PurityOS < Oxidized::Model
  using Refinements

  # Pure Storage Purity OS

  # 提示符正则表达式：匹配 Purity OS 设备提示符
  prompt /\w+@\S+(\s+\S+)*\s?>\s?$/
  # 注释字符：Purity OS 使用井号作为注释
  comment '# '

  # 处理配置列表，清理动态信息
  cmd 'pureconfig list' do |cfg|
    cfg.gsub! /^purealert flag \d+$/, ''
    cfg.gsub! /(.*VEEAM-StorageLUNSnap-[0-9a-f].*)/, ''
    cfg.gsub! /(.*VEEAM-ExportLUNSnap-[0-9A-F].*)/, ''
    # remove empty lines
    cfg.each_line.reject { |line| line.match /^[\r\n\s\u0000#]+$/ }.join
  end

  # SSH 连接配置
  cfg :ssh do
    pty_options(term: "dumb")
    pre_logout 'exit'
  end
end
