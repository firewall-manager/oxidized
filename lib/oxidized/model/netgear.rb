# Netgear 设备模型
# 支持 Netgear 网络设备的配置备份
class Netgear < Oxidized::Model
  using Refinements

  # 注释字符：Netgear 使用感叹号作为注释
  comment '!'
  # 提示符正则表达式：匹配 Netgear 设备提示符
  prompt /^\(?[\w \-+.]+\)? ?[#>] ?$/

  # 处理旧版 Netgear 型号的"show version"分页器
  expect /^--More-- or \(q\)uit$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏密码
    cfg.gsub!(/password (\S+)/, 'password <hidden>')
    # 隐藏加密信息
    cfg.gsub!(/encrypted (\S+)/, 'encrypted <hidden>')
    # 隐藏 SNMP 服务器社区字符串
    cfg.gsub!(/snmp-server community (\S+)$/, 'snmp-server community <hidden>')
    # 隐藏 SNMP 服务器社区字符串（带参数）
    cfg.gsub!(/snmp-server community (\S+) (\S+) (\S+)/, 'snmp-server community \\1 \\2 <hidden>')
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^(User:|Applying Interface configuration, please wait ...)/
    password /^Password:/i
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login do
      # 处理启用密码
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /[pP]assword:\s?$/
        cmd vars(:enable)
      end
    end
    # 设置终端长度
    post_login 'terminal length 0'
    # quit / logout 有时会提示用户：
    #
    #     The system has unsaved changes.
    #     Would you like to save them now? (y/n)
    #
    # 由于在这个简单的 SSH 会话中不会进行任何更改，我们可以安全地选择 "n"
    pre_logout 'quit'
    pre_logout 'n'
  end

  # 处理所有命令的输出
  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    new_cfg << cfg.each_line.to_a[1..-2].join
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    # 移除当前时间信息
    cfg.gsub! /(Current Time\.+ ).*/, '\\1 <removed>'
    comment cfg
  end

  # 处理启动变量信息
  cmd 'show bootvar' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    # 移除系统运行时间信息
    cfg.gsub! /(System Up Time\s+).*/, '\\1 <removed>'
    # 移除当前 SNTP 同步时间信息
    cfg.gsub! /(Current SNTP Synchronized Time:).*/, '\\1 <removed>'
    # 移除当前系统时间信息
    cfg.gsub! /(Current System Time:).*/, '\\1 <removed>'
    cfg
  end
end
