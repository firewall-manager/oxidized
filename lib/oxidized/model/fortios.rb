# Fortinet FortiOS 设备模型
# 支持 Fortinet FortiGate 防火墙的配置备份
class FortiOS < Oxidized::Model
  using Refinements

  # 注释字符：FortiOS 使用井号作为注释
  comment '# '

  # 提示符正则表达式：匹配 FortiOS 设备提示符
  prompt /^(\(\w\) )?([-\w.~]+(\s[(\w\-.)]+)?~?\s?[#>$]\s?)$/

  # 当启用登录后横幅时，需要按 "a" 来登录
  expect /^\(Press\s'a'\sto\saccept\):/ do |data, re|
    send 'a'
    data.sub re, ''
  end

  # 处理分页器
  expect /^--More--\s$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 处理所有命令的输出
  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    new_cfg << cfg.each_line.to_a[1..-2].map { |line| line.gsub(/(conf_file_ver=)(.*)/, '\1<stripped>\3') }.join
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 移除加密配置的私钥
    cfg.gsub! /^(\#private-encryption-key=).+/, '\\1 <configuration removed>'
    # ENC 表示加密密码，secret 表示密钥字符串
    cfg.gsub! /(set .+ ENC) .+/, '\\1 <configuration removed>'
    cfg.gsub! /(set .*secret) .+/, '\\1 <configuration removed>'
    # 许多其他语句也包含敏感字符串
    cfg.gsub! /(set (?:passwd|password|key|group-password|auth-password-l1|auth-password-l2|rsso|history0|history1)) .+/, '\\1 <configuration removed>'
    cfg.gsub! /(set md5-key [0-9]+) .+/, '\\1 <configuration removed>'
    # 移除私钥
    cfg.gsub! /(set private-key ).*?-+END (ENCRYPTED|RSA|OPENSSH) PRIVATE KEY-+\n?"$/m, '\\1<configuration removed>'
    cfg.gsub! /(set privatekey ).*?-+END (ENCRYPTED|RSA|OPENSSH) PRIVATE KEY-+\n?"$/m, '\\1<configuration removed>'
    # 移除证书
    cfg.gsub! /(set ca )"-+BEGIN.*?-+END CERTIFICATE-+"$/m, '\\1<configuration removed>'
    cfg.gsub! /(set csr ).*?-+END CERTIFICATE REQUEST-+"$/m, '\\1<configuration removed>'
    cfg
  end

  # 处理系统状态信息
  cmd 'get system status' do |cfg|
    @vdom_enabled = cfg.match /Virtual domain configuration: (enable|multiple)/
    # 隐藏时间相关信息
    cfg.gsub! /(System time:).*/i, '\\1 <stripped>'
    cfg.gsub! /(Cluster (?:uptime|state change time):).*/, '\\1 <stripped>'
    cfg.gsub! /(Current Time\s+:\s+)(.*)/, '\1<stripped>'
    cfg.gsub! /(Uptime:\s+)(.*)/, '\1<stripped>\3'
    cfg.gsub! /(Last reboot:\s+)(.*)/i, '\1<stripped>\3'
    # 隐藏磁盘使用信息
    cfg.gsub! /(Disk Usage\s+:\s+)(.*)/, '\1<stripped>'
    cfg.gsub! /(^\S+ (?:disk|DB):\s+)(.*)/, '\1<stripped>\3'
    # 隐藏虚拟机注册信息
    cfg.gsub! /(VM Registration:\s+)(.*)/, '\1<stripped>\3'
    # 隐藏数据库版本信息
    cfg.gsub! /(Virus-DB|Extended DB|FMWP-DB|IPS-DB|IPS-ETDB|APP-DB|INDUSTRIAL-DB|Botnet DB|IPS Malicious URL Database|AV AI\/ML Model|IoT-Detect).*/, '\\1 <db version stripped>'
    comment cfg
  end

  # 后处理：收集配置信息
  post do
    cfg = []
    cfg << cmd('config global') if @vdom_enabled

    # 获取高可用状态
    cfg << cmd('get system ha status') do |cfg_ha|
      cfg_ha = cfg_ha.each_line.select { |line| line.match /^(HA Health Status|Mode|Model|Master|Slave|Primary|Secondary|# COMMAND)(\s+)?:/ }.join
      comment cfg_ha
    end

    # 获取硬件状态
    cfg << cmd('get hardware status') do |cfg_hw|
      comment cfg_hw
    end

    # 默认行为：包含自动更新输出（向后兼容）
    # 如果变量 "show_autoupdate" 设置为 false，则不包含
    if defined?(vars(:fortios_autoupdate)).nil? || vars(:fortios_autoupdate)
      cfg << cmd('diagnose autoupdate version') do |cfg_auto|
        cfg_auto.gsub! /(FDS Address\n---------\n).*/, '\\1IP Address removed'
        comment cfg_auto.each_line.reject { |line| line.match /Last Update|Result/ }.join
      end
    end

    cfg << cmd('end') if @vdom_enabled

    # 不同的操作系统有不同的命令 - 我们使用第一个有效的
    # - 对于 fortigate > 7 和可能的早期版本，我们使用：
    #        show | grep .                     # 如 FortiGate GUI 中的备份
    #        show full-configuration | grep .  # 包括默认值的备份
    #   | grep 用于避免 --More-- 提示符
    # - 没有文档说明哪些系统需要不带 | grep 的命令：
    #        show full-configuration
    #        show
    #   如果你知道，请在这里记录并在 github 上提交 PR！
    # 默认情况下，我们使用不包含默认值的配置
    # 如果配置中设置了 fullconfig: true，我们获取完整配置
    commandlist = if vars(:fullconfig)
                    ['show full-configuration | grep .',
                     'show full-configuration', 'show']
                  else
                    ['show | grep .',
                     'show full-configuration', 'show']
                  end

    commandlist.each do |fullcmd|
      fullcfg = cmd(fullcmd)
      # 不显示不支持的设备（如 FortiAnalyzer、FortiManager、FortiMail）
      next if fullcfg.lines[1..3].join =~ /(Parsing error at|command parse error)/

      fullcfg.gsub! /(set comments "Error \(No order (found )?for (account )?ID \d+\) on).*/, '\\1 <stripped>"'

      cfg << fullcfg
      break
    end

    cfg.join
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^[lL]ogin:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 退出命令
    pre_logout "exit\n"
  end
end
