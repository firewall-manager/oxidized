# 博达 (BDCOM) 设备模型
# 支持博达网络设备的配置备份
class BDCOM < Oxidized::Model
  using Refinements

  # 注释字符：博达使用感叹号作为注释
  comment '! '

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏密码信息
    cfg.gsub!(/password \d+ (\S+).*/, '<secret removed>')
    # 隐藏社区字符串
    cfg.gsub!(/community (\S+)/, 'community <hidden>')
    cfg
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.each_line.to_a[0..-2].join
  end

  # 处理运行配置
  cmd 'show running-config'

  # 处理版本信息
  cmd 'show version' do |cfg|
    # 移除运行时间信息
    cfg.gsub! /(\s*uptime is\s*)[0-9:]+/, '\1 <removed>'
    # 移除当前时间信息
    cfg.gsub! /(\s*current time:\s*)[0-9-]+\s+[0-9:]+/, '\1 <removed>'
    # 移除时间戳信息
    cfg.gsub! /(\s*at)\s+[0-9-]+\s+[0-9:]+(,\s*uptime\s+[0-9:]+)?/, '\1 <removed>'
    comment cfg
  end

  # 处理电源状态
  cmd 'show power-status' do |cfg|
    comment cfg
  end

  # 处理风扇状态
  cmd 'show fan-status' do |cfg|
    comment cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end

    # 设置终端长度
    post_login 'terminal length 0'
    # 退出命令
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
