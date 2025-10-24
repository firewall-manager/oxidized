# SpeedTouch 设备模型
# 支持 SpeedTouch 网络设备的配置备份
class SpeedTouch < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 SpeedTouch 设备提示符
  prompt /([\w{}=]+>)$/
  # 注释字符：SpeedTouch 使用感叹号作为注释
  comment '! '

  # 处理登录提示
  expect /login$/ do
    send "\n"
    ""
  end

  # 处理环境列表
  cmd ':env list' do |cfg|
    cfg.each_line.select do |line|
      (not line.match /:env list$/) &&
        (not line.match /{\w+}=>$/)
    end.join
    comment cfg
  end

  # 处理配置转储
  cmd ':config dump' do |cfg|
    cfg.each_line.select do |line|
      (not line.match /:config dump$/) &&
        (not line.match /{\w+}=>$/)
    end.join
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username : /
    password /^Password : /
  end

  # Telnet 连接配置
  cfg :telnet do
    pre_logout 'exit'
  end
end
