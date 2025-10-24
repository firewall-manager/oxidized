# Mellanox MLNX-OS 设备模型
# 支持 Mellanox MLNX-OS 网络设备的配置备份
class MLNXOS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 MLNX-OS 设备提示符（支持主备模式）
  prompt /^\r?\S* \[\S+: (master|standby)\] [#>] $/
  # 注释字符：MLNX-OS 使用双井号作为注释
  comment '## '
  # 清理转义代码
  clean :escape_codes

  # 分页器处理
  # Pager Handling
  # "Normal" pager: "lines 183-204 "
  # Last pager:     "lines 256-269/269 (END) "
  expect /lines \d+-\d+( |\/\d+ \(END\) )/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 处理所有命令的输出，移除动态信息
  cmd :all do |cfg|
    cfg.gsub! /.\x08/, '' # Remove Backspace char
    cfg.gsub! /^CPU load averages:\s.+/, '' # Omit constantly changing CPU info
    cfg.gsub! /^System memory:\s.+/, '' # Omit constantly changing memory info
    cfg.gsub! /^Uptime:\s.+/, '' # Omit constantly changing uptime info
    cfg.gsub! /.+Generated at\s\d+.+/, '' # Omit constantly changing generation time info
    cfg.lines.to_a[2..-3].join
  end

  # 处理敏感信息，隐藏 SNMP 社区字符串和用户密码
  cmd :secret do |cfg|
    cfg.gsub! /(snmp-server community).*/, '   <snmp-server community configuration removed>'
    cfg.gsub! /username (\S+) password (\d+) (\S+).*/, '<secret hidden>'
    cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理设备清单信息
  cmd 'show inventory' do |cfg|
    comment cfg
  end

  # 启用特权模式
  cmd 'enable'

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    password /^Password:\s*/
    post_login 'no cli session paging enable'
    pre_logout "\nexit"
  end
end
