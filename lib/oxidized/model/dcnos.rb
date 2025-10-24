# DCNOS 设备模型
# DCNOS 是 DCN (http://www.dcnglobal.com/) 开发的 ZebOS 衍生版本
# 除了 DCN（现在的云科中国）的产品外，此操作系统类型
# 还支持许多重新品牌的 OEM 设备
# 基于 SNR S2950-24G 7.0.3.5 开发
class DCNOS < Oxidized::Model
  using Refinements

  # DCNOS is a ZebOS derivative by DCN (http://www.dcnglobal.com/)
  # In addition to products by DCN (now Yunke China), this OS type
  # powers a number of re-branded OEM devices.

  # Developed against SNR S2950-24G 7.0.3.5

  # 注释字符：DCNOS 使用感叹号作为注释
  comment '! '

  # 处理所有命令的输出，移除头部信息
  cmd :all do |cfg|
    cfg.cut_head
  end

  # 处理版本信息，移除运行时间信息
  cmd 'show version' do |cfg|
    cfg.gsub! /\s(Uptime is).*/, ''
    comment cfg
  end

  # 处理启动文件信息
  cmd 'show boot-files' do |cfg|
    comment cfg
  end

  # 处理闪存信息
  cmd 'show flash' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^login:/i
    password /^password:/i
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
