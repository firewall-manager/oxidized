# Cisco SMA 设备模型
# 支持 Cisco SMA 设备的配置备份
class CiscoSMA < Oxidized::Model
  using Refinements

  # SMA 提示符 "mail.example.com> "
  # 提示符正则表达式：匹配 Cisco SMA 设备提示符
  prompt /^\r*([-\w. ]+\.[-\w. ]+\.[-\w. ]+[#>]\s+)$/
  # 注释字符：Cisco SMA 使用感叹号作为注释
  comment '! '

  # 选择密码短语显示选项
  expect /using loadconfig command\. \[Y\]>/ do |data, re|
    send "y\n"
    data.sub re, ''
  end

  # 处理分页
  expect /-Press Any Key For More-+.*$/ do |data, re|
    send " "
    data.sub re, ''
  end

  # 处理版本信息
  cmd 'version' do |cfg|
    comment cfg
  end

  # 处理配置信息
  cmd 'showconfig' do |cfg|
    # 删除每次运行都会变化的小时和日期
    # cfg.gsub! /\sCurrent Time: \S+\s\S+\s+\S+\s\S+\s\S+/, ' Current Time:'
    # 删除选择密码短语显示选项
    cfg.gsub! "Do you want to mask the password? Files with masked passwords cannot be loaded", ''
    cfg.gsub! /^\s+y/, ''
    # 删除空格
    cfg.gsub! /\n\s{25}/, ''
    # 删除行后内容
    cfg.gsub! /([\/\-,.\w><@]+)(\s{27})/, "\\1"
    # 添加回车符
    cfg.gsub! /([\/\-,.\w><@]+)(\s{6,8})([\/\-,.\w><@]+)/, "\\1\n\\2\\3"
    # 删除提示符
    cfg.gsub! /^\r*([-\w. ]+\.[-\w. ]+\.[-\w. ]+[#>]\s+)$/, ''
    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    # 退出命令
    pre_logout "exit"
  end
end
