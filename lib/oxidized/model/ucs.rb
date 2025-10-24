# UCS 设备模型
# 支持 Cisco UCS 统一计算系统的配置备份
class UCS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 UCS 设备提示符
  prompt /^(\r?[\w.@_()-]+\#\s?)$/
  # 注释字符：UCS 使用感叹号作为注释
  comment '! '

  # 处理版本简要信息
  cmd 'show version brief' do |cfg|
    comment cfg
  end

  # 处理机箱详细信息
  cmd 'show chassis detail' do |cfg|
    comment cfg
  end

  # 处理结构互连详细信息
  cmd 'show fabric-interconnect detail' do |cfg|
    comment cfg
  end

  # 处理所有配置
  cmd 'show configuration all | no-more' do |cfg|
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
    username /^login:/
    password /^Password:/
  end
end
