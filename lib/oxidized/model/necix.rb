# NecIX 设备模型
# 支持 NecIX 网络设备的配置备份
class NecIX < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 NecIX 设备提示符
  prompt /^(\([\w.-]*\)\s[#$]|^\S+[$#]\s?)$/
  # 注释字符：NecIX 使用感叹号作为注释
  comment '! '
  # 处理分页器
  expect /^--More--$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 处理运行配置，移除当前时间信息
  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-2].join
    cfg.gsub! /^.*Current time.*$/, ''
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login do
      send "configure\n"
    end

    pre_logout do
      send "\cZ"
      send "exit\n"
    end
  end
end
