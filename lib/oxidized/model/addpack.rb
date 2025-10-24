# AddPack 设备模型
# 支持 AddPack VoIP 设备（如 AP100B, AP100_G2, AP700, AP1000, AP1100F）的配置备份
class AddPack < Oxidized::Model
  # Used in AddPack Voip, such as AP100B, AP100_G2, AP700, AP1000, AP1100F

  using Refinements
  # 提示符正则表达式：匹配 AddPack 设备提示符
  PROMPT = /^.*[>#]\s?$/

  # 处理分页显示
  expect /-- [Mm]ore --/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 设置提示符
  prompt PROMPT
  # 启用特权模式
  cmd 'enable'

  # 处理运行配置，清理构建信息
  cmd 'show running-config' do |cfg|
    cfg.gsub! /^Building configuration.../, ''
    cfg.gsub! /^*show running-config/, ''
    cfg.gsub! PROMPT, ''
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /[Ll]ogin:\s?/
    password /[Pp]assword:\s?/
  end
end
