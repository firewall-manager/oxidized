# 瑞斯康达 (RAISECOM) 设备模型
# 支持瑞斯康达网络设备的配置备份
class RAISECOM < Oxidized::Model
  using Refinements

  # 注释字符：瑞斯康达使用感叹号作为注释
  comment '! '
  # 提示符正则表达式：匹配瑞斯康达设备提示符
  prompt /([\w.@-]+[#>]\s?)$/

  # 处理版本信息
  cmd 'show version' do |cfg|
    # 移除系统运行时间信息
    cfg.gsub! /\s(System uptime is ).*/, ' \\1 <removed>'
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    # 隐藏 RADIUS 加密密钥
    cfg.gsub! /\s(^radius-encrypt-key ).*/, ' \\1 <removed>'
    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    # 禁用分页
    post_login 'terminal page-break disable'
    # 退出命令
    pre_logout 'exit'
  end
end
