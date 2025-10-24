# WatchGuard FirewareOS 设备模型
# 支持 WatchGuard 防火墙的配置备份
class FirewareOS < Oxidized::Model
  using Refinements

  # 匹配的提示符模式：
  # [FAULT]WG<managed-by-wsm><master>>
  # WG<managed-by-wsm><master>>
  # WG<managed-by-wsm>>
  # [FAULT]WG<non-master>>
  # [FAULT]WG>
  # WG>

  # 提示符正则表达式：匹配 FirewareOS 设备提示符
  prompt /^\[?\w*\]?\w*?(?:<[\w-]+>)*(#|>)\s*$/
  # 注释字符：FirewareOS 使用双破折号作为注释
  comment  '-- '

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理登录免责声明（在 XTM 11.9.3 中添加）
  expect /^I have read and accept the Logon Disclaimer message. \(yes or no\)\? $/ do |data, re|
    send "yes\n"
    data.sub re, ''
  end

  # 处理系统信息
  cmd 'show sysinfo' do |cfg|
    # 避免因运行时间导致的提交
    cfg = cfg.each_line.reject { |line| line.match /(.*time.*)|(.*memory.*)|(.*cpu.*)/ }
    cfg = cfg.join
    comment cfg
  end

  # 处理配置导出
  cmd 'export config to console'

  # SSH 连接配置
  cfg :ssh do
    # 退出命令
    pre_logout 'exit'
  end
end
