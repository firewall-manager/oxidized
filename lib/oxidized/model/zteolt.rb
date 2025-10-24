# 中兴 OLT 设备模型
# 支持中兴 OLT 设备的配置备份
# 已测试 C320 和 C300 OLT，固件版本 1.2.5P3 和 2.1.0
class ZTEOLT < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配中兴 OLT 设备提示符
  prompt /^([\w.@()-]+[#>]\s?)$/
  # 注释字符：中兴 OLT 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出
  cmd :all do |cfg|
    # 移除无效输入错误信息
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.cut_both
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏 SNMP 社区字符串
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    # 隐藏 TACACS 服务器密钥
    cfg.gsub! /^(tacacs-server (.+ )?key) .+/, '\\1 <secret hidden>'
    # 隐藏用户名和密码
    cfg.gsub! /^username (\S+) privilege (\d+) (\S+).*/, '<secret hidden>'
    # 隐藏启用密码
    cfg.gsub! /^(enable (password|secret)( level \d+)? \d) .+/, '\\1 <secret hidden>'
    cfg
  end

  # 处理运行版本信息
  cmd 'show version-running' do |cfg|
    comment cfg
  end

  # 处理运行补丁信息
  cmd 'show patch-running' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    # 移除时间戳信息
    cfg.gsub! /^timestamp_write: .*\n/, ''
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/i
    password /^Password:/i
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 处理启用密码的首选方式
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    # 设置终端长度
    post_login 'terminal length 0'
    # 退出命令
    pre_logout 'disable'
    pre_logout 'exit'
  end
end
