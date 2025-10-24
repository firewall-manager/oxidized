# Allied Telesis AlliedWare Plus 设备模型
# 支持 Allied Telesis AlliedWare Plus 网络设备的配置备份
# https://www.alliedtelesis.com/products/software/AlliedWare-Plus
class AWPlus < Oxidized::Model
  using Refinements

  # Allied Telesis Alliedware Plus Model#
  # https://www.alliedtelesis.com/products/software/AlliedWare-Plus

  # 提示符正则表达式：匹配 AlliedWare Plus 设备提示符
  prompt /^(\r?[\w.@:\/-]+[#>]\s?)$/
  # 注释字符：AlliedWare Plus 使用感叹号作为注释
  comment '! '

  # 避免需要 "term length 0" 来显示完整配置文件
  # Avoids needing "term length 0" to display full config file.
  expect /--More--/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 移除分页器的垃圾输出，如 VT100 转义码
  # Removes gibberish pager output e.g. VT100 escape codes
  cmd :all do |cfg|
    cfg.gsub! "\e[K", '' # example how to handle pager - cleareol EL0
    cfg.gsub! "\e[7m\e[m", '' # example how to handle pager - Reverse SGR7
    cfg.delete! "\r" # Filters rogue ^M - see issue #415
    cfg.cut_both
  end

  # 从配置文件中移除密码
  # 在全局 oxidized 配置文件中添加 vars "remove_secret: true" 来启用
  # Remove passwords from config file.
  # Add vars "remove_secret: true" to global oxidized config file to enable.
  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(username \S+ privilege \d+) (\S+).*/, '\\1 <secret hidden>'
    cfg.gsub! /^(username \S+ password \d) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(username \S+ secret \d) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(enable (password|secret) \d) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(\s+(?:password|secret)) (?:\d )?\S+/, '\\1 <secret hidden>'
    cfg.gsub! /^(tacacs-server key \d) (\S+)/, '\\1 <secret hidden>'
    cfg
  end

  # 将 "Show system" 输出添加到配置开头
  # Adds "Show system" output to start of config.
  cmd 'Show System' do |cfg|
    comment cfg.insert(0, "--------------------------------------------------------------------------------! \n")
    # Unhash below to write a comment in the config file.
    cfg.insert(0, "Starting: Show system cmd \n")
    cfg << "\n \nEnding: show system cmd"
    comment cfg << "\n--------------------------------------------------------------------------------! \n \n"
    # Removes the following lines from "show system" in output file. This ensures oxidized diffs are meaningful.
    comment cfg.each_line.reject { |line|
              line.match(/^$\n/) || # Remove blank lines in "sh sys"
                line.match(/System Status\s*.*/) ||
                line.match(/RAM\s*:.*/) ||
                line.match(/Uptime\s*:.*/) ||
                line.match(/Flash\s*:.*/) ||
                line.match(/Current software\s*:.*/) ||
                line.match(/Software version\s*:.*/) ||
                line.match(/Build date\s*:.*/)
            }.join
  end

  # 实际获取设备的运行配置
  # Actually get the devices running config#
  cmd 'show running-config' do |cfg|
    cfg
  end

  # Telnet 连接配置，用于检测用户名和密码提示符
  # Config required for telnet to detect username & password prompt.
  cfg :telnet do
    username /login:\s/
    password /^Password:\s/
  end

  # SSH 连接配置，指定换行符
  # Config required for ssh to specify newline characters.
  cfg :telnet, :ssh do
    newline "\r\n"

    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
      # cmd 'terminal length 0' # set so the entire config is output without intervention.
    end

    pre_logout do
      # cmd 'terminal no length' # sets term length back to default on exit.
      send "exit\r\n"
    end
  end
end
