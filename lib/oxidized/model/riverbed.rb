# Riverbed 设备模型
# 支持 Riverbed 网络设备的配置备份
class Riverbed < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 Riverbed 设备提示符
  prompt /^.* *[\w-]+ *[#>] *$/

  # 注释字符：Riverbed 使用感叹号作为注释
  comment '! '

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏 TACACS 服务器密钥
    cfg.gsub! /^( *tacacs-server (.+ )?key) .+/, '\\1 <secret hidden>'
    # 隐藏用户名密码
    cfg.gsub! /^( *username .+ (password|secret) \d) .+/, '\\1 <secret hidden>'
    # 隐藏 NTP 服务器密钥
    cfg.gsub! /^( *ntp server .+ key) .+/, '\\1 <secret hidden>'
    # 隐藏 NTP 对等密钥
    cfg.gsub! /^( *ntp peer .+ key) .+/, '\\1 <secret hidden>'
    # 隐藏 SNMP 服务器社区字符串
    cfg.gsub! /^( *snmp-server community).*/, '\\1 <configuration removed>'
    # 隐藏 IP 安全共享密钥
    cfg.gsub! /^( *ip security shared secret).*/, '\\1 <secret hidden>'
    # 隐藏服务共享密钥（客户端）
    cfg.gsub! /^( *service shared-secret secret client).*/, '\\1 <secret hidden>'
    # 隐藏服务共享密钥（服务器）
    cfg.gsub! /^( *service shared-secret secret server).*/, '\\1 <secret hidden>'
    cfg
  end

  # 获取版本信息并输出为注释
  cmd 'show version' do |cfg|
    cfg = cfg.cut_both

    output = ''
    cfg.each_line do |line|
      line.strip!
      # 提取产品名称
      output << comment("Product name: #{Regexp.last_match(1)}\n") if line =~ /^Product name:\s+(.*)$/
      # 提取产品版本
      output << comment("Product release: #{Regexp.last_match(1)}\n") if line =~ /^Product release:\s+(.*)$/
      # 提取构建 ID
      output << comment("Build ID: #{Regexp.last_match(1)}\n") if line =~ /^Build ID:\s+(.*)$/
      # 提取构建日期
      output << comment("Build date: #{Regexp.last_match(1)}\n") if line =~ /^Build date:\s+(.*)$/
      # 提取构建架构
      output << comment("Build arch: #{Regexp.last_match(1)}\n") if line =~ /^Build arch:\s+(.*)$/
      # 提取构建者
      output << comment("Built by: #{Regexp.last_match(1)}\n") if line =~ /^Built by:\s+(.*)$/
      # 提取产品型号
      output << comment("Product model: #{Regexp.last_match(1)}\n") if line =~ /^Product model:\s+(.*)$/
      # 提取 CPU 数量
      output << comment("Number of CPUs: #{Regexp.last_match(1)}\n") if line =~ /^Number of CPUs:\s+(.*)$/
    end
    output + "\n"
  end

  # 获取硬件信息并输出为注释
  cmd 'show hardware all' do |cfg|
    cfg = cfg.cut_both

    output = ''
    cfg.each_line do |line|
      line.strip!
      # 提取硬件版本
      output << comment("Hardware revision: #{Regexp.last_match(1)}\n") if line =~ /^Hardware revision:\s+(.*)$/
      # 提取主板信息
      output << comment("Mainboard: #{Regexp.last_match(1)}\n") if line =~ /^Mainboard:\s+(.*)$/
      # 提取插槽信息
      if line =~ /^Slot (\d+):\s+\.*\s+(.*)$/
        slot_number = Regexp.last_match(1)
        slot_info = Regexp.last_match(2)
        output << comment("Slot #{slot_number}: #{slot_info}\n")
      end
      # 提取系统 LED 信息
      output << comment("System led: #{Regexp.last_match(1)}\n") if line =~ /^System led:\s+(.*)$/
    end
    output + "\n"
  end

  # 获取序列号信息并输出为注释
  cmd 'show info' do |cfg|
    cfg = cfg.cut_both

    output = ''
    cfg.each_line do |line|
      line.strip!
      # 提取序列号
      output << comment("Serial: #{Regexp.last_match(1)}\n") if line =~ /^Serial:\s+(.*)$/
    end
    output + "\n"
  end

  # 获取运行配置
  cmd 'show running-config' do |cfg|
    cfg = cfg.cut_both

    # 处理配置行，分离注释和命令
    cfg = cfg.each_line.map do |line|
      if line =~ /^(.*##.*?##)(.*)$/
        comment_part = Regexp.last_match(1).strip
        command_part = Regexp.last_match(2).strip
        comment_line = comment(comment_part)
        if command_part.empty?
          comment_line + "\n"
        else
          comment_line + "\n" + command_part + "\n"
        end
      else
        line
      end
    end.join

    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    post_login do
      # 启用特权模式
      cmd 'enable'
      # 设置终端长度
      cmd 'terminal length 0'
      # 设置终端宽度
      cmd 'terminal width 1024'
    end
    # 退出命令
    pre_logout 'exit'
  end
end
