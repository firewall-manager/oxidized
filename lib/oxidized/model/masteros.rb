# MRV MasterOS 设备模型
# 支持 MRV MasterOS 网络设备的配置备份
class MasterOS < Oxidized::Model
  using Refinements

  # MRV MasterOS model #

  # 注释字符：MasterOS 使用感叹号作为注释
  comment '!'

  # 处理敏感信息，隐藏 SNMP 社区字符串和用户密码
  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /username (\S+) password encrypted (\S+) class (\S+).*/, '<secret hidden>'
    cfg
  end

  # 处理所有命令的输出，清理配置头部
  cmd :all do |cfg|
    cfg.cut_both
    cfg.gsub /^(! Configuration ).*/, '!'
  end

  # 处理设备清单信息
  cmd 'show inventory' do |cfg|
    comment cfg.cut_tail
  end

  # 处理插件信息
  cmd 'show plugins' do |cfg|
    comment cfg
  end

  # 处理硬件配置信息
  cmd 'show hw-config' do |cfg|
    comment cfg
  end

  # 处理运行配置，移除前3行
  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-1].join
    cfg
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login 'no pager'
    if vars :enable
      post_login do
        send "enable\n"
        send vars(:enable) + "\n"
      end
    end
    pre_logout 'exit'
  end
end
