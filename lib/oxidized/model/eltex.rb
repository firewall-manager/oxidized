# Eltex 设备模型
# 支持 Eltex 网络设备的配置备份
# 测试设备：MES2324FB Version: 4.0.7.1 Build: 37 (master)
class Eltex < Oxidized::Model
  using Refinements

  # Tested with MES2324FB Version: 4.0.7.1 Build: 37 (master)

  # 提示符正则表达式：匹配 Eltex 设备提示符
  prompt /^\s?[\w.@()-]+[#>]\s?$/
  # 注释字符：Eltex 使用感叹号作为注释
  comment '! '

  # 处理所有命令的输出，清理错误信息
  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.cut_both
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(enable (password|secret)( level \d+)? \d) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(\s+(?:password|secret)) (?:\d )?\S+/, '\\1 <secret hidden>'
    cfg.gsub! /^(tacacs-server (.+ )?key) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^((tacacs|radius) server [^\n]+\n( +[^\n]+\n)*\s+key) [^\n]+$/m, '\1 <secret hidden>'
    cfg.gsub! /username (\S+) privilege (\d+) (\S+).*/, '<secret hidden>'
    cfg.gsub! /^username \S+ password \d \S+/, '<secret hidden>'
    cfg.gsub! /^enable password \d \S+/, '<secret hidden>'
    cfg.gsub! /wpa-psk ascii \d \S+/, '<secret hidden>'
    cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^(User Name):/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 处理额外密码的首选方式
    # preferred way to handle additional passwords
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    post_login 'terminal datadump'
    # 禁用 MES2424 的 CLI 分页
    # disable cli pagination for MES2424
    post_login 'set cli pagination off'
    pre_logout 'disable'
    pre_logout 'exit'
  end
end
