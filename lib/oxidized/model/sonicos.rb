# SonicOS 设备模型
# 支持 SonicWall NSA 系列防火墙的配置备份
class SonicOS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 SonicOS 设备提示符
  prompt /^\w+@[\w-]+>\(?.+\)?\s?/
  # 注释字符：SonicOS 使用感叹号作为注释
  comment '! '

  # 接受策略消息（参见 Issue #3339）。在 6.5 和 7.1 上测试过
  expect /Accept The Policy Banner \(yes\)\?\r\nyes: $/ do |data, re|
    send "yes\n"
    data.sub re, ''
  end

  # 处理所有命令的输出，移除第一行和最后一行
  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏 CLI FTP 密码
    cfg.gsub! /cli ftp password default \d,(\S+)/, 'cli ftp password default <secret hidden> \2'
    # 隐藏密钥
    cfg.gsub! /secret \d,(\S+)/, 'secret <secret hidden> \2'
    # 隐藏共享密钥
    cfg.gsub! /shared-secret \d,(\S+)/, 'shared-secret <secret hidden> \2'
    # 隐藏密码
    cfg.gsub! /password \d,(\S+)/, 'password <secret hidden> \2'
    # 隐藏密码短语
    cfg.gsub! /passphrase password \d,(\S+)/, 'passphrase password <secret hidden> \2'
    # 隐藏绑定密码
    cfg.gsub! /bind-password \d,(\S+)/, 'bind-password <secret hidden> \2'
    # 隐藏认证 SHA1 密钥
    cfg.gsub! /authentication sha1 \d,(\S+)/, 'authentication sha1 <secret hidden> \2'
    # 隐藏加密 AES 密钥
    cfg.gsub! /encryption aes \d,(\S+)/, 'encryption aes <secret hidden> \2'
    # 隐藏 SMTP 密码
    cfg.gsub! /smtp-pass \d,(\S+)/, 'smtp-pass <secret hidden> \2'
    # 隐藏 POP 密码
    cfg.gsub! /pop-pass \d,(\S+)/, 'pop-pass <secret hidden> \2'
    # 隐藏 SSL VPN 密码
    cfg.gsub! /sslvpn password \d,(\S+)/, 'sslvpn password <secret hidden> \2'
    # 隐藏管理员密码
    cfg.gsub! /administrator password \d,(\S+)/, 'administrator password <secret hidden> \2'
    # 隐藏 FTP 密码
    cfg.gsub! /ftp password \d,(\S+)/, 'ftp password <secret hidden> \2'
    # 隐藏共享密钥
    cfg.gsub! /shared-key \d,(\S+)/, 'shared-key <secret hidden> \2'
    # 隐藏 WPA 密码短语
    cfg.gsub! /wpa passphrase \d,(\S+)/, 'wpa passphrase <secret hidden> \2'
    cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    cfg = comment clean cfg
    cfg << "\n"
  end

  # 处理当前配置
  cmd 'show current-config' do |cfg|
    # 移除冒号开头的行
    cfg.gsub! /^: [^\n]*\n/, ''
    clean cfg
  end

  # SSH 连接配置
  cfg :ssh do
    # 禁用 CLI 分页器会话
    post_login 'no cli pager session'
    # 退出命令
    pre_logout 'exit'
  end

  # 清理配置输出
  # @param cfg [String] 配置字符串
  # @return [String] 清理后的配置
  def clean(cfg)
    out = []
    cfg.each_line do |line|
      # 跳过日期信息
      next if line =~ /date \d{4}:\d{2}:\d{2}/
      # 跳过时间信息
      next if line =~ /time \d{2}:\d{2}:\d{2}/
      # 跳过系统时间信息
      next if line =~ /system-time "\d{2}\/\d{2}\/\d{4} \d{2}:\d{2}:\d{2}.\d+"/
      # 跳过系统运行时间信息
      next if line =~ /system-uptime "(?:\s+up\s+\d+\s+|\d+ \w+(?:, \d+ \w+)*)"/
      # 跳过校验和信息
      next if line =~ /checksum \d+/

      # 移除回车符
      line = line[1..-1] if line[0] == "\r"
      out << line.strip
    end
    out = out.join "\n"
    out << "\n"
  end
end
