# Fire Linux OS 设备模型
# 支持 Cisco FTD (FirePOWER) 系列设备的配置备份
# Fire Linux OS 是 Cisco 新 FTD (FirePOWER) 系列设备运行的系统，后端与 ASA 基本相同
class FireLinuxOS < Oxidized::Model
  using Refinements

  # Fire Linux OS is what the new FTD (FirePOWER) series devices from Cisco run. At the backend, it's mostly identical to ASA's.

  # 提示符正则表达式：匹配 Fire Linux OS 设备提示符
  prompt /^[#>]\(?.+\)? ?$/
  # 注释字符：Fire Linux OS 使用感叹号作为注释
  comment '! '

  # 处理语法错误，发送 CTRL-U 和换行符获取新提示符
  expect /^Syntax error: .*\n.*$/ do |data, re|
    # The firepower does not remove the entered command, so
    # Send CTRL-U and \n for a fresh prompt
    send "\x15\n"
    data.sub re, ''
  end

  # 处理所有命令的输出，清理错误信息和 ANSI 转义码
  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    # Ged rid of ANSI escape codes
    cfg.gsub! /\e\[[0-?]*[ -\/]*[@-~]\r?/, ''
    cfg.cut_both
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    cfg.gsub! /enable password (\S+) (.*)/, 'enable password <secret hidden> \2'
    cfg.gsub! /username (\S+) password (\S+) (.*)/, 'username \1 password <secret hidden> \3'
    cfg.gsub! /(ikev[12] ((remote|local)-authentication )?pre-shared-key) (\S+)/, '\1 <secret hidden>'
    cfg.gsub! /^(aaa-server TACACS\+? \(\S+\) host.*\n\skey) \S+$/mi, '\1 <secret hidden>'
    cfg.gsub! /ldap-login-password (\S+)/, 'ldap-login-password <secret hidden>'
    cfg.gsub! /^snmp-server host (.*) community (\S+)/, 'snmp-server host \1 community <secret hidden>'
    cfg
  end

  # 处理系统版本信息，移除运行时间信息
  cmd 'show version system' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match /(\s+up\s+\d+\s+)|(.*days.*)/ }
    cfg = cfg.join
    comment cfg
  end

  # 处理库存信息
  cmd 'show inventory' do |cfg|
    comment cfg
  end

  # 处理运行配置，移除冒号开头的行
  cmd 'show running-config all' do |cfg|
    cfg = cfg.each_line.to_a[3..-1].join
    cfg.gsub! /^: [^\n]*\n/, ''
    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    pre_logout 'exit'
  end
end
