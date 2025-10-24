# Adtran 设备模型
# 支持 Adtran 设备的配置备份
class Adtran < Oxidized::Model
  using Refinements

  # Adtran

  # 提示符正则表达式：匹配 Adtran 设备提示符
  prompt /([\w.@-]+[#>]\s?)$/

  # 处理所有命令的输出，清理回车符和空行
  cmd :all do |cfg|
    cfg.each_line.to_a[2..-2].map { |line| line.delete("\r").rstrip }.join("\n") + "\n"
  end

  # 处理敏感信息，隐藏密码
  cmd :secret do |cfg|
    cfg.gsub!(/password (\S+)/, 'password <hidden>')
    cfg
  end

  # 处理运行配置，移除时间戳信息
  cmd 'show running-config' do |cfg|
    # Strip out line at the top which displays the current date/time
    # ! Created                         : Mon Jun 26 2023 10:07:07
    cfg.gsub! /! Createds+:.*\n/, ''
  end

  # SSH 连接配置
  cfg :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login 'terminal length 0'
    pre_logout 'exit'
    sleep 1
  end
end
