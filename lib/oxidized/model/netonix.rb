# Netonix 设备模型
# 支持 Netonix 网络设备的配置备份
class Netonix < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 Netonix 设备提示符
  prompt /^[\w\s().@_\/:-]+#/

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理配置文件，输出 JSON 格式配置
  cmd 'cat config.json;echo'

  # SSH 连接配置
  cfg :ssh do
    post_login 'cmdline'
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
