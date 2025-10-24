# ML66 设备模型
# 支持 ML66 网络设备的配置备份
class ML66 < Oxidized::Model
  # 注释字符：ML66 使用感叹号作为注释
  comment '! '
  # 提示符正则表达式：匹配 ML66 设备提示符
  prompt /.*#/

  # 处理用户认证提示
  expect /User:.*$/ do |data, re|
    send "admin_user\n"
    send "#{@node.auth[:password]}\n"
    data.sub re, ''
  end

  # 处理版本信息，移除运行时间
  cmd 'show version' do |cfg|
    cfg.gsub! "Uptime", ''
    comment cfg
  end

  # 处理硬件清单信息
  cmd 'show inventory hw all' do |cfg|
    comment cfg
  end

  # 处理软件清单信息
  cmd 'show inventory sw all' do |cfg|
    comment cfg
  end

  # 处理许可证状态信息
  cmd 'show license status all' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config'

  # SSH 连接配置
  cfg :ssh do
    pre_logout 'logout'
  end
end
