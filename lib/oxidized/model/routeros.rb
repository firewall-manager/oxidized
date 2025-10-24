# MikroTik RouterOS 设备模型
# 支持 MikroTik RouterOS 设备的配置备份
class RouterOS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 RouterOS 设备提示符
  prompt /\[\w+@\S+(\s+\S+)*\]\s?>\s?$/
  # 注释字符：RouterOS 使用井号作为注释
  comment "# "

  # 处理所有命令的输出
  cmd :all do |cfg|
    # 移除 ANSI 颜色代码
    cfg.gsub! /\x1B\[([0-9]{1,3}(;[0-9]{1,3})*)?[m|K]/, ''
    if screenscrape
      cfg = cfg.cut_both
      # 清理回车符
      cfg.gsub! /^\r+(.+)/, '\1'
      cfg.gsub! /([^\r]*)\r+$/, '\1'
    end
    # 移除尾随空白字符
    cfg.lines.map { |line| line.rstrip }.join("\n") + "\n"
  end

  # 处理系统资源信息
  cmd '/system resource print' do |cfg|
    # 提取关键系统信息
    cfg = cfg.each_line.grep(/(version|factory-software|total-memory|cpu|cpu-count|total-hdd-space|architecture-name|board-name|platform):/).join
    comment cfg
  end

  # 处理系统包更新信息
  cmd '/system package update print' do |cfg|
    version_line = cfg.each_line.grep(/installed-version:\s|current-version:\s/)[0]
    @ros_version = /([0-9])/.match(version_line)[0].to_i
    comment version_line
  end

  # 处理系统历史记录
  cmd '/system history print without-paging' do |cfg|
    comment cfg
  end

  # 后处理：导出配置
  post do
    logger.debug "Running /export for routeros version #{@ros_version}"
    # 根据版本和设置选择导出命令
    run_cmd = if vars(:remove_secret)
                '/export hide-sensitive'
              elsif (not @ros_version.nil?) && (@ros_version >= 7)
                '/export show-sensitive'
              else
                '/export'
              end
    cmd run_cmd do |cfg|
      # 清理换行符
      cfg.gsub! /\\\r?\n\s+/, ''
      # 移除基于时间的系统注释
      cfg.gsub! "# inactive time\r\n", ''
      # 移除间歇性 VRRP/CARP 冲突注释
      cfg.gsub! /# received packet from \S+ bad format\r\n/, ''
      # 移除间歇性 POE 短路注释
      cfg.gsub! "# poe-out status: short_circuit\r\n", ''
      # 移除临时固件升级注释
      cfg.gsub! "# Firmware upgraded successfully, please reboot for changes to take effect!\r\n", ''
      # 移除间歇性接口未就绪注释
      cfg.gsub! /# \S+ not ready\r\n/, ''
      # 移除间歇性重启需要注释（如 IPv6 设置）
      cfg.gsub! /# .+ please restart the device in order to apply the new setting\r\n/, ''
      cfg = cfg.split("\n")
      # 移除日期时间和 'by RouterOS' 注释（v6）
      cfg.reject! { |line| line[/^#\s\w{3}\/\d{2}\/\d{4}.*$/] }
      # 移除日期时间和 'by RouterOS' 注释（v7）
      cfg.reject! { |line| line[/^#\s\d{4}-\d{2}-\d{2}.*$/] }
      cfg.join("\n") + "\n"
    end
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Login:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 退出命令
    pre_logout 'quit'
  end

  # SSH 连接配置
  cfg :ssh do
    # 在 exec 通道中运行命令
    exec true
  end
end
