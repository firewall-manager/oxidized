# Cisco 小型企业交换机设备模型
# 支持 Cisco Small Business 300, 500, and ESW2 系列交换机的配置备份
# http://www.cisco.com/c/en/us/support/switches/small-business-300-series-managed-switches/products-release-notes-list.html
class CiscoSMB < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 Cisco SMB 设备提示符
  prompt /^\r?([\w.@()-]+[#>]\s?)$/
  # 注释字符：Cisco SMB 使用感叹号作为注释
  comment '! '

  # 处理密码过期提示
  expect '^.*Your password has exceeded the maximum lifetime.*$' do
    send 'N'
    ""
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    lines = cfg.each_line.to_a[1..-2]
    # 从响应开头移除 \r
    lines[0].gsub!(/^\r.*?/, '') unless lines.empty?
    lines.join
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏 SNMP 社区字符串
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    # 隐藏用户名和权限信息
    cfg.gsub! /username (\S+) privilege (\d+) (\S+).*/, '<secret hidden>'
    # 隐藏加密密码
    cfg.gsub! /^(username \S+ password encrypted) \S+(.*)/, '\\1 <secret hidden> \\2'
    # 隐藏启用密码
    cfg.gsub! /^(enable password level \d+ encrypted) \S+/, '\\1 <secret hidden>'
    # 隐藏 RADIUS 服务器密钥
    cfg.gsub! /^(encrypted radius-server key).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(encrypted radius-server host .+ key) \S+(.*)/, '\\1 <secret hidden> \\2'
    # 隐藏 TACACS 服务器密钥
    cfg.gsub! /^(encrypted tacacs-server key).*/, '\\1 <secret hidden>'
    cfg.gsub! /^(encrypted tacacs-server host .+ key) \S+(.*)/, '\\1 <secret hidden> \\2'
    # 隐藏 SNTP 认证密钥
    cfg.gsub! /^(encrypted sntp authentication-key \d+ md5) .*/, '\\1 <secret hidden>'
    cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    # 移除运行时间信息
    cfg.gsub! /.*Uptime for this control.*/, ''
    cfg.gsub! /.*System restarted.*/, ''
    cfg.gsub! /uptime is\ .+/, '<uptime removed>'
    comment cfg
  end

  # 处理启动变量
  cmd 'show bootvar' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[0..-1].join
    # 移除当前配置头部
    cfg.gsub! /^Current configuration : [^\n]*\n/, ''
    # 处理 NTP 时钟周期
    cfg.sub! /^(ntp clock-period).*/, '! \1'
    # 移除 MPLS TE 带宽配置
    cfg.gsub! /^ tunnel mpls traffic-eng bandwidth[^\n]*\n*(
                  (?: [^\n]*\n*)*
                  tunnel mpls traffic-eng auto-bw)/mx, '\1'
    cfg
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    username /User ?[nN]ame:/
    password /^\r?Password:/

    post_login do
      if vars(:enable) == true
        cmd 'enable'
      elsif vars(:enable)
        cmd 'enable', /^\r?Password:$/
        cmd vars(:enable)
      end
    end

    # 禁用分页器
    post_login 'terminal datadump'
    # 设置终端宽度
    post_login 'terminal width 0'
    # 设置终端长度
    post_login 'terminal len 0'
    # 退出命令（exit 返回到上一级权限，无法从 exec(#) 退出）
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
