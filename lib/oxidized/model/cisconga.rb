# Cisco NGA 设备模型
# 支持 Cisco NGA 设备的配置备份
class CiscoNGA < Oxidized::Model
  using Refinements

  # 注释字符：Cisco NGA 使用井号作为注释
  comment '# '
  # 提示符正则表达式：匹配 Cisco NGA 设备提示符
  prompt /([\w.@-]+[#>]\s?)$/

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理配置信息
  cmd 'show configuration' do |cfg|
    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    # 设置终端长度
    post_login 'terminal length 0'
    # 退出命令
    pre_logout 'exit'
  end
end
