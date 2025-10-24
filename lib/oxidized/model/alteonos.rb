# AlteonOS 设备模型
# 支持 AlteonOS 网络设备的配置备份
class ALTEONOS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 AlteonOS 设备提示符
  prompt  /^\(?.+\)?\s?[#>]/

  # 注释字符：AlteonOS 使用感叹号作为注释
  comment '! '

  # 处理敏感信息，隐藏密码
  cmd :secret do |cfg|
    # 隐藏管理员密码
    cfg.gsub!(/^([\s\t]*admpw ).*/, '\1 <password removed>')
    # 隐藏密码
    cfg.gsub!(/^([\s\t]*pswd ).*/, '\1 <password removed>')
    # 隐藏加密密钥
    cfg.gsub!(/^([\s\t]*esecret ).*/, '\1 <password removed>')
    cfg
  end

  # 处理配置转储，移除时间戳和版本信息
  # 移除以下信息：
  # /* Configuration dump taken 14:10:20 Fri Jul 28, 2017 (DST)
  # /* Configuration last applied at 16:17:05 Fri Jul 14, 2017
  # /* Configuration last save at 16:17:43 Fri Jul 14, 2017
  # /* Version 29.0.3.12, vXXXXXXXX,  Base MAC address XXXXXXXXXXX
  # /* To restore SSL Offloading configuration and management HTTPS access,
  # /* it is recommended to include the private keys in the dump.
  # /* To restore SSL Offloading configuration and management HTTPS access,it is recommended
  # /* to include the private keys in the dump.
  cmd 'cfg/dump' do |cfg|
    # 移除配置转储时间信息
    cfg.gsub! /^([\s\t\/*]*Configuration).*/, ''
    # 移除版本信息
    cfg.gsub! /^([\s\t\/*]*Version).*/, ''
    # 移除恢复建议信息
    cfg.gsub! /^([\s\t\/*]*To restore ).*/, ''
    cfg.gsub! /^([\s\t\/*]*it is recommended to include).*/, ''
    cfg.gsub! /^([\s\t\/*]*to include ).*/, ''
    cfg
  end

  # 处理显示私钥的提示
  expect /^Display private keys\?\s?\[y\/n\]: $/ do |data, re|
    send "n\r"
    data.sub re, ''
  end

  # 处理退出时同步到对等方的确认
  expect /^Confirm Sync to Peer\s?\[y\/n\]: $/ do |data, re|
    send "n\r"
    data.sub re, ''
  end

  # 处理未保存配置的警告
  expect /^(WARNING: There are unsaved configuration changes).*/ do |data, re|
    send "n\r"
    data.sub re, ''
  end

  # SSH 连接配置
  cfg :ssh do
    # 退出命令
    pre_logout 'exit'
  end
end
