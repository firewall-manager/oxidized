# Siklu MultiHaul TG 设备模型
# 支持 Siklu MultiHaul TG 网络设备的配置备份
# 需要在源中定义模型为 SikluMHTG
class SikluMHTG < Oxidized::Model
  using Refinements

  # Siklu MultiHaul TG#
  # Requires source to define the model as SikluMHTG #

  # 提示符正则表达式：匹配 Siklu MultiHaul TG 设备提示符
  prompt /^\r?MH-[TN]\d{3}@\w{2,8}>$/

  # 处理分页显示
  expect /--More--/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 处理启动配置，清理控制字符
  cmd 'show startup' do |cfg|
    cfg.gsub! /[\b]|\e\[A|\e\[2K/, ''
    cfg.cut_both
  end

  # SSH 连接配置
  cfg :ssh do
    pre_logout 'quit'
  end
end
