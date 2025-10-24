# ZynOS ADSL 设备模型
# 支持 Zyxel ADSL 网络设备的配置备份
# 用于 Zyxel ADSL 设备，如 AAM1212-51
class ZyNOSADSL < Oxidized::Model
  using Refinements

  # Used in Zyxel ADSL, such as AAM1212-51

  # 提示符正则表达式：匹配 ZynOS ADSL 设备提示符
  prompt /^.*>\s?$/
  # 注释字符：ZynOS ADSL 使用双分号作为注释
  comment ';; '

  # 处理配置显示
  cmd 'config show all nopause'

  # Telnet 连接配置
  cfg :telnet do
    password /^Password:/i
  end
end
