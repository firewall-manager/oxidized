# Cisco VPN 3000 设备模型
# 支持 Cisco VPN 3000 集中器的配置备份
class CiscoVPN3k < Oxidized::Model
  using Refinements

  # 用于 Cisco VPN3000 集中器
  # 它有错误的代码 227 回复，在尾括号前有空白字符
  # "227 Passive mode OK (172,16,0,9,4,9 )"
  # 所以如果可能的话使用主动 FTP。或者修补 net/ftp

  # 处理配置命令
  cmd 'CONFIG'

  # FTP 连接配置
  cfg :ftp do
  end
end
