# FastIron 设备模型
# 支持 Brocade FastIron 网络设备的配置备份
class FastIron < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 FastIron 设备提示符
  prompt /^([\w.@()-]+[#>]\s?)$/
  # 注释字符：FastIron 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出，清理错误信息
  cmd :all do |cfg|
    # cfg.gsub! /\cH+\s{8}/, ''         # example how to handle pager
    # cfg.gsub! /\cH+/, ''              # example how to handle pager
    # get rid of errors for commands that don't work on some devices
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.cut_both
  end

  # 处理版本信息，提取关键信息
  cmd 'show version' do |cfg|
    comments = []
    comments << cfg.lines.first
    lines = cfg.lines
    lines.each_with_index do |line, _i|
      comments << "Version: #{Regexp.last_match(1)}" if line =~ /^\s+SW: Version (.*)$/

      if line =~ /^\s+Compressed Boot-Monitor Image size = \d+, Version:(.*)$/
        comments << "Boot-Monitor Version: #{Regexp.last_match(1)}"
      end

      comments << "Serial: #{Regexp.last_match(1)}" if line =~ /^\s+Serial  #:(.*)$/
    end
    comments << "\n"
    comment comments.join "\n"
  end

  # 处理模块信息
  cmd 'show module' do |cfg|
    cfg.gsub! /^$\n/, ''
    cfg.gsub! /^/, 'Modules: ' unless cfg.empty?
    comment "#{cfg}\n"
  end

  # 处理媒体信息
  cmd 'show media | exclude EMPTY' do |cfg|
    comment cfg
  end

  # 处理硬件信息
  cmd 'show hardware-info' do |cfg|
    comment cfg
  end

  # 处理堆叠信息
  cmd 'show stack' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config'

  # Telnet 连接配置
  cfg :telnet do
    username /^(.* login|Username): /
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 处理额外密码的首选方式
    # preferred way to handle additional passwords
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /[pP]assword:/
        cmd vars(:enable)
      end
    end
    post_login 'skip-page-display'
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
