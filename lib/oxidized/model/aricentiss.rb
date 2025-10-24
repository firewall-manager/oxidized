# Aricent ISS 设备模型
# 支持 Aricent ISS 网络设备的配置备份
# 开发测试版本：
# #show version
# Switch ID       Hardware Version                Firmware Version
# 0               SSE-G48-TG4   (P2-01)           1.0.16-9
# and
# # show version
# Switch ID       Hardware Version                Firmware Version
# 0               MBM-XEM-002  (B6-01)            2.1.3-25
# Developed against:
# #show version
# Switch ID       Hardware Version                Firmware Version
# 0               SSE-G48-TG4   (P2-01)           1.0.16-9
# and
# # show version
# Switch ID       Hardware Version                Firmware Version
# 0               MBM-XEM-002  (B6-01)            2.1.3-25

class AricentISS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 Aricent ISS 设备提示符
  prompt /^(\e\[27m)?[ \r]*[\w-]+# ?$/

  # SSH 连接配置
  cfg :ssh do
    # "pagination" 在某些（早期）版本中拼写错误（至少 1.0.16-9）
    # 1.0.18-15 已知包含正确的拼写
    # "pagination" was misspelled in some (earlier) versions (at least 1.0.16-9)
    # 1.0.18-15 is known to include the corrected spelling
    post_login 'no cli pagination'
    post_login 'no cli pagignation'
    # 从固件 2.0 开始，分页处理方式不同
    # 此配置在会话结束后重置
    # Starting firmware 2.0, pagination is done differently.
    # This configuration is reset after the session ends.
    post_login 'conf t; set cli pagination off; exit'
    pre_logout 'exit'
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    # * 删除包含命令的第一行和包含提示符的最后一行
    # * 移除回车符
    # * Drop first line that contains the command, and the last line that
    #   contains a prompt
    # * Strip carriage returns
    cfg.delete("\r").each_line.to_a[1..-2].join
  end

  # 处理敏感信息，隐藏 SNMP 社区字符串
  cmd :secret do |cfg|
    cfg.gsub(/^(snmp community) .*/, '\1 <hidden>')
  end

  # 处理系统信息，移除设备运行时间
  cmd 'show system information' do |cfg|
    cfg.sub! /^Device Up Time.*\n/, ''
    cfg.delete! "\r"
    comment(cfg).rstrip
  end

  # 处理运行配置，添加注释和格式化
  cmd 'show running-config' do |cfg|
    comment_next = 0
    cfg.each_line.map do |l|
      next '' if l =~ /^Building configuration/

      comment_next = 2 if l =~ /^Switch ID.*Hardware Version.*Firmware Version/

      if comment_next.positive?
        comment_next -= 1
        next comment(l)
      end

      l
    end.join.rstrip
  end
end
