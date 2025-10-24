# D-Link 设备模型
# 支持 D-Link 交换机的配置备份
class Dlink < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 D-Link 交换机提示符
  prompt /[\w.@()\/:-]+[#>]\s?$/
  # 注释字符：D-Link 使用井号作为注释
  comment '# '

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏 SNMP 社区字符串
    cfg.gsub! /^(create snmp community) \S+/, '\\1 <removed>'
    # 隐藏 SNMP 组信息
    cfg.gsub! /^(create snmp group) \S+/, '\\1 <removed>'
    cfg
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.each_line.to_a[2..-2].map { |line| line.delete("\r").rstrip }.join("\n") + "\n"
  end

  # 处理交换机信息
  cmd 'show switch' do |cfg|
    # 移除不断变化的运行时间信息
    cfg.gsub! /^System Uptime\s.+/, '' # 省略不断变化的运行时间信息
    cfg.gsub! /^System up time\s.+/, '' # 省略不断变化的运行时间信息
    cfg.gsub! /^System Time\s.+/, '' # 省略不断变化的运行时间信息
    cfg.gsub! /^RTC Time\s.+/, '' # 省略不断变化的运行时间信息
    comment cfg
  end

  # 处理 VLAN 信息
  cmd 'show vlan' do |cfg|
    comment cfg
  end

  # 处理当前配置
  cmd 'show config current'

  # Telnet 连接配置
  cfg :telnet do
    username /\r*([\w\s.@()\/:-]+)?([Uu]ser[Nn]ame|[Ll]ogin):/
    password /\r*[Pp]ass[Ww]ord:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 禁用分页
    post_login 'disable clipaging'
    # 启用管理员模式
    post_login 'enable admin' if vars(:enable) == true
    # 退出命令
    pre_logout 'logout'
  end
end
