# Lenovo NOS 设备模型
# 支持 Lenovo NOS 网络设备的配置备份
class LenovoNOS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 Lenovo NOS 设备提示符
  prompt /^([\w.@()-]+[#>]\s?)$/
  # 注释字符：Lenovo NOS 使用感叹号作为注释
  comment '! '

  # 扩展注释方法，添加头部信息
  def comment_ext(header, output)
    data = ''
    data << header
    data << "\n"
    data << output
    data << "\n"
    comment data
  end

  # 处理所有命令的输出，清理错误信息
  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.cut_both
  end

  # 处理敏感信息，隐藏各种密码和密钥
  cmd :secret do |cfg|
    cfg.gsub! /^(enable password) \S+(.*)/, '\\1 <secret hidden>\\2'
    cfg.gsub! /^(access user \S+ password) \S+(.*)/, '\\1 <secret hidden>\\2'
    cfg.gsub! /^(snmp-server \S+-community) \S+(.*)/, '\\1 <secret hidden>\\2'
    cfg.gsub! /^(tacacs-server \S+ \S+ ekey) \S+(.*)/, '\\1 <secret hidden>\\2'
    cfg.gsub! /^(ntp message-digest-key \S+ md5-ekey) \S+(.*)/, '\\1 <secret hidden>\\2'
    cfg.gsub! /(.* password )"[0-9a-f]+"(.*)/, '\\1<secret hidden>\\2'
    cfg.gsub! /(.*ekey )"[0-9a-f]+"(.*)/, '\\1<secret hidden>\\2'
    cfg
  end

  # 处理命令行界面模式选择
  expect /^Select Command Line Interface mode.*iscli.*:/ do |data, re|
    send "iscli\n"
    data.sub re, ''
  end

  # 处理版本信息，移除动态信息
  cmd 'show version' do |cfg|
    cfg = cfg.each_line.to_a

    cfg = cfg.reject { |line| line.match /^System Information at/ }
    cfg = cfg.reject { |line| line.match /^Switch has been up for/ }
    cfg = cfg.reject { |line| line.match /^Last boot:/ }
    cfg = cfg.reject { |line| line.match /^Temperature / }
    cfg = cfg.reject { |line| line.match /^Power Consumption/ }
    cfg = cfg.reject { |line| line.match /^Fan/ }

    cfg = cfg.join
    comment_ext("=== show version ===", cfg)
  end

  # 处理启动信息
  cmd 'show boot' do |cfg|
    comment_ext("=== show boot ===", cfg)
  end

  # 处理收发器信息
  cmd 'show transceiver' do |cfg|
    comment_ext("=== show transceiver ===", cfg)
  end

  # 处理软件密钥信息
  cmd 'show software-key' do |cfg|
    comment_ext("=== show software-key ===", cfg)
  end

  # 处理运行配置，移除当前配置头部和不稳定行
  cmd 'show running-config' do |cfg|
    cfg.gsub! /^Current configuration:[^\n]*\n/, ''
    if vars(:remove_unstable_lines) == true
      cfg.gsub! /(.* password )"[0-9a-f]+"(.*)/, '\\1<unstable line hidden>\\2'
      cfg.gsub! /(.* administrator-password )"[0-9a-f]+"(.*)/, '\\1<unstable line hidden>\\2'
      cfg.gsub! /(.*ekey )"[0-9a-f]+"(.*)/, '\\1<unstable line hidden>\\2'
    end
    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    # 处理额外密码的首选方式
    # preferred way to handle additional passwords
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    post_login 'terminal-length 0'
    pre_logout 'exit'
  end
end
