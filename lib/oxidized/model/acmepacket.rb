# ACME Packet 设备模型
# 支持 Oracle ACME Packet 3k, 4k, 6k 系列设备的配置备份
class ACMEPACKET < Oxidized::Model
  using Refinements

  # Oracle ACME Packet 3k, 4k, 6k series

  # 提示符正则表达式：匹配 ACME Packet 设备提示符
  prompt /^\r*([\w.@()-\/]+[#>]\s?)$/

  # 注释字符：ACME Packet 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出
  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    new_cfg << cfg.cut_both
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    password /^Password:/i
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 处理额外密码的首选方式
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
