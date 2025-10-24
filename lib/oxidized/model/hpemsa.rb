# HPE MSA 设备模型
# 支持 HPE MSA 存储设备的配置备份
class HpeMsa < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 HPE MSA 设备提示符
  prompt /^#\s?$/

  # 处理配置信息
  cmd 'show configuration'

  # SSH 连接配置
  cfg :ssh do
    post_login 'set cli-parameters pager disabled'
    pre_logout 'exit'
  end
end
