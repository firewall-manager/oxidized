# Arista EOS 设备模型
# 支持 Arista EOS 系列交换机的配置备份
class EOS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 EOS 设备提示符
  prompt /^.+[#>]$/
  # 注释字符：EOS 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出，移除首尾行
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏 SNMP 社区字符串
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    # 隐藏密钥
    cfg.gsub! /(secret \w+) (\S+).*/, '\\1 <secret hidden>'
    # 隐藏密码
    cfg.gsub! /(password \d+) (\S+).*/, '\\1 <secret hidden>'
    # 隐藏启用密码
    cfg.gsub! /^(enable (?:secret|password)).*/, '\\1 <configuration removed>'
    # 隐藏不支持的收发器服务许可证
    cfg.gsub! /^(service unsupported-transceiver).*/, '\\1 <license key removed>'
    # 隐藏 TACACS 服务器密钥
    cfg.gsub! /^(tacacs-server key \d+).*/, '\\1 <configuration removed>'
    # 隐藏 RADIUS 服务器密钥
    cfg.gsub! /^(radius-server .+ key \d) \S+/, '\\1 <radius secret hidden>'
    # 隐藏密钥（6个空格前缀）
    cfg.gsub! /( {6}key) (\h+ 7) (\h+).*/, '\\1 <secret hidden>'
    # 隐藏认证和加密密钥
    cfg.gsub! /(localized|auth (md5|sha\d{0,3})|priv (des|aes\d{0,3})) \S+/, '\\1 <secret hidden>'
    cfg
  end

  # 处理设备清单信息
  cmd 'show inventory | no-more' do |cfg|
    comment cfg
  end

  # 处理运行配置，排除时间戳
  cmd 'show running-config | no-more | exclude ! Time:' do |cfg|
    cfg
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        # 将 enable: true 解释为不需要密码提示
        unless vars(:enable).is_a? TrueClass
          expect /[pP]assword:\s?$/
          send vars(:enable) + "\n"
        end
        expect /^.+[#>]\s?$/
      end
      # 设置终端长度
      post_login 'terminal length 0'
    end
    # 退出命令
    pre_logout 'exit'
  end
end
