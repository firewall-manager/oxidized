# Fujitsu PY 设备模型
# 支持 Fujitsu PY 系列交换机的配置备份
class FujitsuPY < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 Fujitsu PY 设备提示符
  prompt /^(\([\w.-]*\)\s#|^\S+#\s)$/
  # 注释字符：Fujitsu PY 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理版本信息（1Gbe 交换机）
  # 1Gbe switch
  cmd 'show version' do |cfg|
    cfg.gsub! /^(<ERROR> : 2 : format error)$/, ''
    comment cfg
  end

  # 处理系统信息（10Gbe 交换机）
  # 10Gbe switch
  cmd 'show system information' do |cfg|
    cfg.gsub! /^Current-time : [\w\s:]*$/, ''
    cfg.gsub! /^(\s{33}\^)$/, ''
    cfg.gsub! /^(% Invalid input detected at '\^' marker.)$/, ''
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login 'no pager'
    post_login 'terminal pager disable'
    pre_logout do
      send "quit\n"
      send "n\n"
    end
  end
end
