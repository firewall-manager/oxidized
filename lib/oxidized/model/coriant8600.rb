# Coriant 8600 设备模型
# 支持 Coriant 8600 网络设备的配置备份
class Coriant8600 < Oxidized::Model
  using Refinements

  # 注释字符：Coriant 8600 使用井号作为注释
  comment '# '

  # 提示符正则表达式：匹配 Coriant 8600 设备提示符
  prompt /^[^\s#>]+[#>]$/

  # 处理硬件清单信息
  cmd 'show hw-inventory' do |cfg|
    comment cfg
  end

  # 处理闪存信息
  cmd 'show flash' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show run' do |cfg|
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^user name:$/
    password /^password:$/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    pre_logout 'exit'
    post_login 'enable'
    post_login 'terminal more off'
  end
end
