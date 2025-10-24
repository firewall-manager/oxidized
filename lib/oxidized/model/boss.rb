# Extreme BOSS 设备模型
# 支持 Extreme Baystack Operating System Software (BOSS) 的配置备份
# 创建者：danielcoxman@gmail.com
# 创建日期：2017年5月15日
# 已在 ers3510, ers5530, ers4850, ers5952 上测试
# SSH 和 Telnet 已测试，包括横幅和无横幅情况
class Boss < Oxidized::Model
  using Refinements

  # 注释字符：BOSS 使用感叹号作为注释
  comment '! '
  # 提示符正则表达式：匹配 BOSS 设备提示符
  prompt /^[^\s#>]+[#>]$/

  # 处理横幅
  # 要在 BOSS 上禁用横幅，配置参数为 "banner disabled"
  expect /Enter Ctrl-Y to begin\./ do |data, re|
    send "\cY"
    data.sub re, ''
  end

  # 处理自上次登录以来的失败重试
  # 除了实现 RADIUS 认证外，没有已知的禁用方法
  expect /Press ENTER to continue/ do |data, re|
    send "\n"
    data.sub re, ''
  end

  # 处理旧版 BOSS 示例 ers55xx, ers56xx 上的菜单
  # 要在 BOSS 上禁用菜单，配置参数为 "cmd-interface cli"
  expect /ommand Line Interface\.\.\./ do |data, re|
    send "c"
    data.sub re, ''
    send "\n"
    data.sub re, ''
  end

  # 需要适当的格式化
  cmd('') { |cfg| comment "#{cfg}\n" }

  # 执行系统信息检查并查看是否支持堆叠
  cmd 'show sys-info' do |cfg|
    @stack = true if cfg =~ /Stack/
    # 移除系统运行时间信息
    cfg.gsub! /(^((.*)sysUpTime(.*))$)/, 'removed sysUpTime'
    cfg.gsub! /(^((.*)sysNtpTime(.*))$)/, 'removed sysNtpTime'
    cfg.gsub! /(^((.*)sysRtcTime(.*))$)/, 'removed sysNtpTime'
    # 移除时间戳
    cfg.gsub! /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} .*/, ''
    comment "#{cfg}\n"
  end

  # 如果是堆叠，则收集堆叠信息
  cmd 'show stack-info' do |cfg|
    if @stack
      # 移除时间戳
      cfg.gsub! /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} .*/, ''
      comment "#{cfg}\n"
    end
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg.gsub! /^show running-config/, '! show running-config'
    # 移除时间戳
    cfg.gsub! /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} .*/, ''
    cfg.gsub! /^[^\s#>]+[#>]$/, ''
    cfg.gsub! /^! clock set.*/, '! removed clock set'
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /Username: /
    password /Password: /
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 退出命令
    pre_logout 'logout'
    # 设置终端长度
    post_login 'terminal length 0'
    # 设置终端宽度
    post_login 'terminal width 132'
  end
end
