# frozen_string_literal: true

# F5OS 设备模型
# 支持 F5OS 网络设备的配置备份
class F5OS < Oxidized::Model
  # 注释字符：F5OS 使用感叹号作为注释
  comment '!'
  # 提示符正则表达式：匹配 F5OS 设备提示符
  prompt(/^([\w.@()-]+ ?[#>]\s+)$/)

  # 获取运行配置
  cmd 'show running-config'

  # SSH 连接配置
  cfg :ssh do
    post_login do
      # 禁用分页器
      cmd 'paginate false'
    end
    # 退出命令
    pre_logout 'exit'
  end
end
