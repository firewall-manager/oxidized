# Cisco NX-OS 设备模型
# 支持 Cisco Nexus 系列交换机的配置备份
class NXOS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 NX-OS 设备提示符
  prompt /^(\r?[\w.@_()-]+\#\s?)$/
  # 注释字符：NX-OS 使用感叹号作为注释
  comment '! '

  # 过滤配置输出，清理回车符和提示符
  # @param cfg [String] 配置字符串
  # @return [String] 过滤后的配置
  def filter(cfg)
    cfg.gsub! /\r\n?/, "\n"
    cfg.gsub! prompt, ''
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏 SNMP 社区字符串
    cfg.gsub! /^(snmp-server community).*/, '\\1 <secret hidden>'
    # 隐藏 SNMP 用户认证信息
    cfg.gsub! /^(snmp-server user (\S+) (\S+) auth (\S+)) (\S+) (priv) (\S+)/, '\\1 <secret hidden> '
    # 隐藏 SNMP 主机配置
    cfg.gsub! /^(snmp-server host.*? )\S+( udp-port \d+)?$/, '\\1<secret hidden>\\2'
    # 隐藏 SNMP MIB 社区映射
    cfg.gsub! /^(snmp-server mib community-map) \S+ ?(.*)/, '\\1 <secret hidden> \\2'
    # 隐藏密码
    cfg.gsub! /(password \d+) (\S+)/, '\\1 <secret hidden>'
    # 隐藏 RADIUS 服务器密钥
    cfg.gsub! /^(radius-server .*key(?: \d+)?) \S+/, '\\1 <secret hidden>'
    # 隐藏 TACACS 服务器密钥
    cfg.gsub! /^(tacacs-server .*key(?: \d+)?) \S+/, '\\1 <secret hidden>'
    cfg
  end

  # 处理 show version 命令输出
  cmd 'show version' do |cfg|
    cfg = filter cfg
    # 过滤掉运行时间、启动闪存大小等不必要的信息
    cfg = cfg.each_line.take_while { |line| not line.match(/uptime|bootflash:\s+\d+\skB|sysmgrcli_show_flash_size/i) }
    comment cfg.join
  end

  # 处理 show inventory all 命令输出
  cmd 'show inventory all' do |cfg|
    cfg = filter cfg
    comment cfg
  end

  # 处理 show running-config 命令输出
  cmd 'show running-config' do |cfg|
    cfg = filter cfg
    # 为 show run 命令添加注释
    cfg.gsub! /^(show run.*)$/, '! \1'
    # 移除时间戳信息
    cfg.gsub! /^!Time:[^\n]*\n/, ''
    # 移除提示符行
    cfg.gsub! /^[\w.@_()-]+\#.*$/, ''
    cfg
  end

  # SSH 和 Telnet 连接配置
  cfg :ssh, :telnet do
    # 设置终端长度
    post_login 'terminal length 0'
    # 退出命令
    pre_logout 'exit'
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^login:/
    password /^Password:/
  end
end
