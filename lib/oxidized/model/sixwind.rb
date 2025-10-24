# SixWind 设备模型
# 支持 SixWind 网络设备的配置备份
class SixWind < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 SixWind 设备提示符
  prompt /^[\w\s().@_\/:-]+> $/
  # 注释字符：SixWind 使用井号作为注释
  comment '# '

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    cfg.gsub!(/(?<!  {1})(?:password|secret) (?:\d )?\S+/, '\\1 <secret hidden>') # double space to exclude radius password template
    cfg
  end

  # 处理产品版本信息
  cmd 'show product version' do |cfg|
    comment cfg
  end

  # 处理配置信息
  cmd 'show config' do |cfg|
    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    post_login 'cliconfig pager enabled false'
    pre_logout 'exit'
  end
end
