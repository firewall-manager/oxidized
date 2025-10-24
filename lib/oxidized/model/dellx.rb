# Dell X 系列设备模型
# 支持 Dell X 系列交换机的配置备份
class DellX < Oxidized::Model
  using Refinements

  # Used in Dell X-Series Switches

  # 提示符正则表达式：匹配 Dell X 系列设备提示符
  prompt /[#>]$/
  # 注释字符：Dell X 系列使用感叹号作为注释
  comment '! '

  # 处理分页提示
  expect /(^.*)?+[mM]ore:+.*$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 处理所有命令的输出，移除首尾行
  cmd :all do |cfg|
    cfg.each_line.to_a[1..-3].join
  end

  # 处理敏感信息，隐藏用户名和密码
  cmd :secret do |cfg|
    cfg.gsub! /^(username \S+ password (?:encrypted )?)\S+(.*)/, '\1<hidden>\2'
    cfg
  end

  # 处理版本信息，检测堆叠设备并清理运行时间信息
  cmd 'show version' do |cfg|
    @stackable = true if @stackable.nil? && (cfg =~ /(U|u)nit\s/)
    cfg = cfg.split("\n").reject { |line| line[/Up\sTime/] }
    comment cfg.join("\n") + "\n"
  end

  # 处理系统信息，使用自定义清理方法
  cmd 'show system' do |cfg|
    clean cfg
  end

  # 处理运行配置，清理 sflow 超时信息
  cmd 'show running-config' do |cfg|
    cfg.sub(/^(sflow \S+ destination owner \S+ timeout )\d+$/, '! \1<timeout>')
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    username /[uU]ser\s?[nN]ame:$/
    password /[pP]assword:$/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end

    pre_logout "logout"
    pre_logout "exit"
  end

  # 清理系统信息输出，处理堆叠设备
  def clean(cfg)
    out = []
    skip_blocks = 0
    cfg.each_line do |line|
      # If this is a stackable switch we should skip this block of information
      if line.match(/Up\sTime|Temperature|Power Suppl(ies|y)|Fans/i) && (@stackable == true)
        skip_blocks = 1
        # Some switches have another empty line. This is identified by this line having a colon
        skip_blocks = 2 if line =~ /:/
      end
      # If we have lines to skip do this until we reach and empty line
      if skip_blocks.positive?
        skip_blocks -= 1 if /\S/ !~ line
        next
      end
      out << line.strip
    end
    out = out.reject { |line| line[/Up\sTime/] }
    out = comment out.join "\n"
    out << "\n"
  end
end
