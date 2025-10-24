# Extreme/Avaya VOSS 设备模型
# 支持 Extreme/Avaya VSP 操作系统软件 (VOSS) 的配置备份
# 作者：danielcoxman@gmail.com
# 创建日期：2019年3月16日
# 测试设备：vsp4k 和 vsp8k
class Voss < Oxidized::Model
  using Refinements

  # Extreme/Avaya VSP Operating System Software(VOSS)
  # Created by danielcoxman@gmail.com
  # March 16, 2019
  # This was tested on vsp4k and vsp8k

  # 注释字符：VOSS 使用井号作为注释
  comment '# '

  # 提示符正则表达式：匹配 VOSS 设备提示符
  prompt /^[^\s#>]+[#>]$/

  # 登录后格式化所需
  # needed for proper formatting after post_login
  cmd('') { |cfg| comment "#{cfg}\n" }

  # 获取系统信息并移除温度、功率等变化信息
  # Get sys-info and remove information that changes such has temperature and power
  cmd 'show sys-info' do |cfg|
    cfg.gsub! /(^((.*)SysUpTime(.*))$)/, 'removed SysUpTime'
    cfg.gsub! /^((.*)Temperature Info :(.*\r?\n){4})/, 'removed Temperature Info and 3 more lines'
    cfg.gsub! /(^((.*)AmbientTemperature(.*):(.*))$)/, 'removed AmbientTemperature'
    cfg.gsub! /(^((.*)Last Change(.*):(.*))$)/, 'remove Last Change'
    cfg.gsub! /(^((.*)Last Statistic Reset(.*):(.*))$)/, 'removed Last Statistic Reset'
    cfg.gsub! /(^((.*)Last Vlan Change(.*):(.*))$)/, 'removed Last Vlan Change'
    cfg.gsub! /(^((.*)Temperature(.*):(.*))$)/, 'removed Temperature'
    cfg.gsub! /(^((.*)Total Power Usage(.*):(.*))$)/, 'removed Total Power Usage'
    comment "#{cfg}\n"
  end

  # 使用 more 命令查看配置而不是 show run
  # more the config rather than doing a show run
  cmd 'more config.cfg' do |cfg|
    cfg.gsub! /^[^\s#>]+[#>]$/, ''
    cfg.gsub! /^more config.cfg/, '# more config.cfg'
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /Login: $/
    password /Password: $/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    pre_logout 'exit'
    post_login 'enable'
    post_login 'terminal more disable'
  end
end
