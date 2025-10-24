# Coriant TMOS 设备模型
# 支持 Coriant TMOS 网络设备的配置备份
class CoriantTmos < Oxidized::Model
  using Refinements

  # 注释字符：Coriant TMOS 使用井号作为注释
  comment '# '

  # 提示符正则表达式：匹配 Coriant TMOS 设备提示符
  prompt /^[^\s#]+#\s$/

  # 处理节点详细信息
  cmd 'show node extensive' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show run' do |cfg|
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Login:\s$/
    password /^Password:\s$/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    pre_logout 'exit'
    post_login 'enable config terminal length 0'
  end
end
