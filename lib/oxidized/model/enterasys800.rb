# Enterasys 800 设备模型
# 支持 Enterasys 800 系列设备的配置备份
# 测试设备：08H20G4-24 Fast Ethernet Switch Firmware: Build 01.01.01.0017
class Enterasys800 < Oxidized::Model
  using Refinements

  # Enterasys 800 models #
  # Tested with 08H20G4-24 Fast Ethernet Switch Firmware: Build 01.01.01.0017
  # 注释字符：Enterasys 800 使用井号作为注释
  comment '# '

  # 提示符正则表达式：匹配 Enterasys 800 设备提示符
  prompt /([\w (:.@-]+[#>]\s?)$/

  # Telnet 连接配置
  cfg :telnet do
    username /UserName:/
    password /PassWord:/
  end

  # Telnet 连接配置，禁用分页
  cfg :telnet do
    post_login 'disable clipaging'
  end

  # Telnet 连接配置，退出命令
  cfg :telnet do
    pre_logout 'logout'
  end

  # 处理所有命令的输出，清理格式
  cmd :all do |cfg|
    cfg = cfg.cut_both
    cfg = cfg.gsub /^[\r\n]|^\s\s\s/, ''
    cfg = cfg.gsub "Command: show config effective", ''
    cfg
  end

  # 处理有效配置
  cmd 'show config effective'
end
