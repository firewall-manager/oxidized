# 华为 SmartAX 设备模型
# 支持华为 SmartAX GPON/EPON/DOCSIS 网络接入设备的配置备份
class SmartAX < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配华为 SmartAX 设备提示符
  prompt /^([\w.-]+[>#])$/
  # 注释字符：华为 SmartAX 使用井号作为注释
  comment '#'

  # Telnet 连接配置
  cfg :telnet do
    username /^>>User name:$/
    password /^>>User password:$/
  end

  # SSH 和 Telnet 连接配置
  cfg :ssh, :telnet do
    # 启用特权模式
    post_login "enable"
    # 禁用交互模式
    post_login "undo interactive"
    # 禁用智能模式
    post_login "undo smart"
    # 启用滚动模式
    post_login "scroll"
    # 退出命令
    pre_logout "quit"
  end

  # 处理当前配置
  # 'display current-configuration' 返回内存中存储的当前配置
  # 'display saved-configuration' 返回文件系统中存储的配置，用于重启时加载
  cmd 'display current-configuration' do |cfg|
    cfg.cut_both
  end
end
