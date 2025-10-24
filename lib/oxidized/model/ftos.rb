# Force10 FTOS 设备模型
# 支持 Force10 FTOS 系列交换机的配置备份
class FTOS < Oxidized::Model
  using Refinements

  # 注释字符：FTOS 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出
  cmd :all do |cfg|
    # 移除前两行和最后两行
    cfg.each_line.to_a[2..-2].join
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏 SNMP 社区字符串
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    # 隐藏密钥
    cfg.gsub! /(secret \d* {0,1})\S+(.*)/, '\\1<secret hidden>\\2'
    # 隐藏密码哈希
    cfg.gsub! /(password \d+) \S+(.*)/, '\\1 <hash hidden>\\2'
    # 隐藏 SNMP 服务器社区
    cfg.gsub! /(^snmp-server.*version \S+) \S+(.*)/, '\\1 <community removed>\\2'
    # 隐藏 RADIUS 服务器密钥
    cfg.gsub! /(^radius-server.*key \d )\S+/, '\\1<hash hidden>\\2'
    cfg
  end

  # 处理设备清单信息
  cmd 'show inventory' do |cfg|
    # 旧版本的 FTOS 偶尔会返回触发编码错误的数据
    cfg.encode!("UTF-8", invalid: :replace, undef: :replace, replace: "")
    comment cfg
  end

  # 处理媒体清单信息
  cmd 'show inventory media' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    # 移除前三行
    cfg = cfg.each_line.to_a[3..-1].join
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Login:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 设置终端长度
    post_login 'terminal length 0'
    # 设置终端宽度
    post_login 'terminal width 0'
    # 处理启用密码
    if vars :enable
      post_login do
        send "enable\n"
        send vars(:enable) + "\n"
      end
    end
    # 退出命令
    pre_logout 'exit'
  end
end
