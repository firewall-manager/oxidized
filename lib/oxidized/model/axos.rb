# AxOS 设备模型
# 支持 AxOS 网络设备的配置备份
class AxOS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 AxOS 设备提示符
  prompt /(\x1b\[\?7h)?([\w.@()-]+\#\s?)$/
  # 注释字符：AxOS 使用感叹号作为注释
  comment '! '

  # 处理运行配置，禁用分页
  cmd 'show running-config | nomore' do |cfg|
    cfg.cut_head
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_tail
  end

  # SSH 连接配置
  cfg :ssh do
    pre_logout 'exit'
  end
end
