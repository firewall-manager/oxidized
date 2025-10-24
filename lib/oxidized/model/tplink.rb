# TP-Link 设备模型
# 支持 TP-Link 网络设备的配置备份
class TPLink < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 TP-Link 设备提示符
  prompt /^\r?([\w.@()-]+[#>]\s?)$/
  # 注释字符：TP-Link 使用感叹号作为注释
  comment '! '

  # 处理分页器
  # 解决有时缺少空格的 "\s?" 问题
  expect /Press\s?any\s?key\s?to\s?continue\s?\(Q\s?to\s?quit\)/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 发送回车符，因为命令中的 \n 不够
  # 检查行是否以提示符 >,# 或 \r,\nm 结尾，否则发送 \r
  expect /[^>#\r\n]$/ do |data, re|
    send "\r"
    data.sub re, ''
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    # 移除不需要的分页行
    cfg.gsub! /^Press any key to contin.*/, ''
    # 标准化换行符
    cfg.gsub! /(\r|\r\n|\n\r)/, "\n"
    # 移除空行
    cfg.each_line.reject { |line| line.match /^[\r\n\s\u0000#]+$/ }.join
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏启用密码
    cfg.gsub! /^enable password (\S+)/, 'enable password <secret hidden>'
    # 隐藏用户密码
    cfg.gsub! /^user (\S+) password (\S+) (.*)/, 'user \1 password <secret hidden> \3'
    # 隐藏 SNMP 服务器社区字符串
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    # 隐藏密钥
    cfg.gsub! /secret (\d+) (\S+).*/, '<secret hidden>'
    cfg
  end

  # 处理系统信息
  cmd 'show system-info' do |cfg|
    # 移除系统时间信息
    cfg.gsub! /(System Time\s+-).*/, '\\1 <stripped>'
    # 移除运行时间信息
    cfg.gsub! /(Running Time\s+-).*/, '\\1 <stripped>'
    comment cfg.each_line.to_a[3..-3].join
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    lines = cfg.each_line.to_a[1..-1]
    # 在 "end" 后截断配置
    lines[0..lines.index("end\n")].join
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    username /^User ?[nN]ame:/
    password /^\r?Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login do
      # 处理启用密码
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end

    pre_logout do
      # 退出命令
      send "exit\r"
      send "logout\r"
    end
  end
end
