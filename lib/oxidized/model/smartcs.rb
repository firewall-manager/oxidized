# SmartCS 设备模型
# 支持 SmartCS 网络设备的配置备份
class SmartCS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 SmartCS 设备提示符
  prompt /^\r?([\w.@() -]+[#>]\s?)$/
  # 注释字符：SmartCS 使用井号作为注释
  comment '# '

  # 处理分页显示
  expect /-more <Press SPACE for another page, 'q' to quit>-/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg
  end

  # 处理版本信息，添加格式化注释
  cmd 'show version' do |cfg|
    comment cfg.insert(0, "--------------------------------------------------------------------------------! \n")
    # Unhash below to write a comment in the config file.
    cfg.insert(0, "Starting: show version cmd \n")
    cfg << "\n \nEnding: show version cmd"
    comment cfg << "\n--------------------------------------------------------------------------------! \n \n"
    comment cfg
  end

  # 处理配置信息，移除多余空格
  cmd 'show config' do |cfg|
    # remove "Press SPACE for another page" add SPACE(\s)
    cfg.gsub! /\s{5,}/, ""
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 处理额外密码的首选方式
    # preferred way to handle additional passwords
    post_login do
      pw = vars(:enable)
      pw ||= ""
      send "su\r"
      expect /[pP]assword:\s?$/
      cmd pw
    end
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
