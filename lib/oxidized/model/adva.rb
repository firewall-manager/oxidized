# ADVA 设备模型
# 支持 ADVA 设备的配置备份
#
# 重要提示：要使此功能正常工作，必须为用于获取配置的用户禁用 cli-paging
#
# IMPORTANT: To get this working, cli-paging must be disabled
# for the user that is used to fetch the configuration.

class ADVA < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 ADVA 设备提示符
  prompt /\w+-+[#>]\s?$/
  # 注释字符：ADVA 使用井号作为注释
  comment '# '

  # 处理敏感信息，隐藏社区字符串
  cmd :secret do |cfg|
    cfg.gsub! /community "[^"]+"/, 'community "<hidden>"'
    cfg
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理运行配置差异，移除准备配置文件信息
  cmd 'show running-config delta' do |cfg|
    cfg.each_line.reject { |line| line.match /^Preparing configuration file.*/ }.join
  end

  # 处理系统信息，移除时间相关动态信息
  cmd 'show system' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match /(up time|local time)/i }.join

    cfg = "COMMAND: show system\n\n" + cfg
    cfg = comment cfg
    "\n\n" + cfg
  end

  # 选择网络元素
  cmd 'network-element ne-1'

  # 处理机架信息
  cmd 'show shelf-info' do |cfg|
    cfg = "COMMAND: show shelf-info\n\n" + cfg
    cfg = comment cfg
    "\n\n" + cfg
  end

  # 后处理：收集端口信息
  post do
    ports = []
    ports_output = ''

    # 获取端口列表
    cmd 'show ports' do |cfg|
      cfg.each_line do |line|
        port = line.match(/\|((access|network)[^|]+)\|/)
        ports << port if port
      end
    end

    # 为每个端口获取详细信息
    ports.each do |port|
      port_command = 'show ' + port[2] + '-port ' + port[1]

      ports_output << cmd(port_command) do |cfg|
        cfg = "COMMAND: " + port_command + "\n\n" + cfg
        cfg = comment cfg
        "\n\n" + cfg
      end
    end

    ports_output
  end

  # SSH 连接配置
  cfg :ssh do
    pre_logout 'logout'
  end
end
