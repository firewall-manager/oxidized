# ZynOS GS 设备模型
# 支持 Zyxel GS1900 交换机的配置备份
# 用于 Zyxel GS1900 交换机，已通过 GS1900-8 测试
class ZyNOSGS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 ZynOS GS 设备提示符
  prompt /^.*# $/
  # 注释字符：ZynOS GS 使用感叹号作为注释
  comment '! '

  # 处理分页器
  expect /^--More--$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 替换所有使用的 vt100 控制序列
  expect /\e\[\??\d+(;\d+)*[A-Za-z]/ do |data, re|
    data.gsub re, ''
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    # 移除系统运行时间信息
    cfg.gsub! /(System Up Time:) \S+(.*)/, '\\1 <time>'
    # 移除垃圾 vt100 控制序列
    # 退格 0x07 字符或转义字符 + 控制字符
    cfg.gsub! /[\b]|\e\[A|\e\[2K/, ''
    # 移除空行
    cfg.gsub! "\n\n", "\n"
    cfg
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    username /^(User name|.*Username):/
    password /^\r?Password:/
  end

  # Telnet 连接配置
  cfg :telnet do
    pre_logout do
      send "exit\r"
    end
  end

  # SSH 连接配置
  cfg :ssh do
    pre_logout do
      # 是的，GS1900 交换机需要两次退出！
      send "exit\n"
      send "exit\n"
    end
  end
end
