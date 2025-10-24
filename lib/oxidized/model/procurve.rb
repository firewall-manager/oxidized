# HP ProCurve 设备模型
# 支持 HP ProCurve 系列交换机的配置备份
class Procurve < Oxidized::Model
  using Refinements

  # 前一个命令重复后跟 "\eE"，有时会出现在最后一行
  # SSH 交换机提示符可能以 \r 开头，后跟提示符本身，正则表达式 ([\w\s.-]+[#>] )，结束该行
  # Telnet 交换机可能以各种 vt100 控制字符开头，正则表达式 (\e\[24;[0-9][hH])，后跟提示符，然后
  # 至少 3 个其他 vt100 字符
  # 提示符正则表达式：匹配 HP ProCurve 设备提示符
  prompt /(^\r|\e\[24;[0-9][hH])?([\w\s.-]+[#>] )($|(\e\[24;[0-9][0-9]?[hH]){3})/
  # 注释字符：HP ProCurve 使用感叹号作为注释
  comment '! '

  # 将下一行控制序列替换为换行符
  expect /(\e\[1M\e\[\??\d+(;\d+)*[A-Za-z]\e\[1L)|(\eE)/ do |data, re|
    data.gsub re, "\n"
  end

  # 替换所有使用的 vt100 控制序列
  expect /\e\[\??\d+(;\d+)*[A-Za-z]/ do |data, re|
    data.gsub re, ''
  end

  # 处理分页提示
  expect /Press any key to continue(\e\[\??\d+(;\d+)*[A-Za-z])*$/ do
    send ' '
    ""
  end

  # 处理交换机编号输入
  expect /Enter switch number/ do
    send "\n"
    ""
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg = cfg.cut_both
    cfg = cfg.gsub /^\r/, ''
    # 对通过 telnet 发送 vt100 控制字符的旧交换机的额外过滤
    cfg.gsub! /\e\[\??\d+(;\d+)*[A-Za-z]/, ''
    # 对随时间明显变化的功耗报告的额外过滤
    cfg.gsub! /^(.*AC [0-9]{3}V\/?([0-9]{3}V)?) *([0-9]{1,3}) (.*)/, '\\1 <removed> \\4'
    # 移除在所有型号上都不支持的失败命令
    cfg.gsub! /^Invalid input: [A-Za-z-]+\n/, ''
    cfg
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏 SNMP 社区字符串
    cfg.gsub! /^(snmp-server community) \S+(.*)/, '\\1 <secret hidden> \\2'
    # 隐藏 SNMP 主机配置
    cfg.gsub! /^(snmp-server host \S+) \S+(.*)/, '\\1 <secret hidden> \\2'
    # 隐藏 RADIUS 服务器密钥
    cfg.gsub! /^(radius-server host \S+ key) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(radius-server key).*/, '\\1 <configuration removed>'
    # 隐藏 TACACS 服务器密钥
    cfg.gsub! /^(tacacs-server host \S+ key) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(tacacs-server key).*/, '\\1 <secret hidden>'
    cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理模块信息
  cmd 'show modules' do |cfg|
    comment cfg
  end

  # 处理接口收发器信息
  cmd 'show interfaces transceiver' do |cfg|
    comment cfg
  end

  # 处理闪存信息
  cmd 'show flash' do |cfg|
    comment cfg
  end

  # 处理系统信息（并非所有型号都支持）
  cmd 'show system-information' do |cfg|
    cfg = cfg.split("\n")[0..-8].join("\n")
    comment cfg
  end

  # 处理系统信息（并非所有型号都支持）
  cmd 'show system information' do |cfg|
    cfg = cfg.each_line.reject do |line|
      line.match /(.*CPU.*)|(.*Up Time.*)|(.*Total.*)|(.*Free.*)|(.*Lowest.*)|(.*Missed.*)/
    end
    cfg = cfg.join
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config'

  # Telnet 连接配置
  cfg :telnet do
    username /Username:/
    password /Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 处理额外密码的首选方式
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    # 禁用分页
    post_login 'no page'
    # 退出命令
    pre_logout "logout\ny\nn"
  end

  # SSH 连接配置
  cfg :ssh do
    # 设置 PTY 选项
    pty_options(chars_wide: 1000)
  end
end
