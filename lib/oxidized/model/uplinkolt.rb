# UPLINK OLT 设备模型
# 支持 UPLINK OLT 设备的配置备份
class UPLINKOLT < Oxidized::Model
  # 提示符正则表达式：匹配 UPLINK OLT 设备提示符
  prompt /^([\w.@()-]+[#>]\s?)$/
  # 注释字符：UPLINK OLT 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出，清理格式
  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.gsub!(/^show running-config$/, '')
    cfg.gsub!(/^.*\s*#\s*$/, '')
    # Remove leading and trailing whitespace
    cfg.strip!
    # Remove empty lines
    cfg.gsub!(/^\s*$/, '')
    cfg
  end

  # 进入配置终端模式
  cmd 'configure terminal' do
    # Enter configure terminal mode
    cmd 'show version' do |cfg|
      cfg.gsub! /^show version/, ''
      comment cfg
    end
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg.gsub! /^Current configuration:/, ''
    cfg
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    username /^Login:/i
    password /^Password:/i
    # preferred way to handle additional passwords
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    post_login 'terminal length 0'
    pre_logout 'exit'
    pre_logout 'disable'
    pre_logout 'exit'
  end
end
