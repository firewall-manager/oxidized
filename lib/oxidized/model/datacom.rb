# 迪普 (DataCom) 设备模型
# 支持迪普网络设备的配置备份
class DataCom < Oxidized::Model
  using Refinements

  # 注释字符：迪普使用感叹号作为注释
  comment '! '

  # 处理分页提示
  expect /^--More--\s+$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_head.cut_both.cut_tail
  end

  # 处理固件信息
  cmd 'show firmware' do |cfg|
    comment cfg
  end

  # 处理系统信息
  cmd 'show system' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg.cut_head
  end

  # SSH 连接配置
  cfg :ssh do
    password /^Password:\s$/
    pre_logout 'exit'
  end

  # Telnet 连接配置
  cfg :telnet do
    username /login:\s$/
    password /^Password:\s$/
    pre_logout 'exit'
  end
end
