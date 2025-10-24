# Zhone OLT 设备模型
# 支持 Zhone OLT/MetroE/DSL 设备的配置备份
# 注意：ONT 使用完全不同的 CLI
class ZhoneOLT < Oxidized::Model
  using Refinements

  # Zhone OLT/MetroE/DSL devices (ONT uses a completely different CLI)

  # 提示符可以是任何内容，但默认为 'zXX>'，我们总是使用 hostname>
  # the prompt can be anything on zhone, but it defaults to 'zXX>' and we
  # always use hostname>
  prompt /^(\r*[\w.@():-]+>\s?)$/
  # 注释字符：Zhone OLT 使用井号作为注释
  comment '# '

  # 处理敏感信息，隐藏各种密码和密钥
  cmd :secret do |cfg|
    cfg.gsub! /^(set configsyncpasswd = ) \S+/, '\\1 <removed>'
    cfg.gsub! /^(set user-pass = ) \S+/, '\\1 <removed>'
    cfg.gsub! /^(set auth-key = ) \S+/, '\\1 <removed>'
    cfg.gsub! /^(set priv-key = ) \S+/, '\\1 <removed>'
    cfg.gsub! /^(set ftp-password = ) \S+/, '\\1 <removed>'
    cfg.gsub! /^(set community-name = ) \S+/, '\\1 <removed>'
    cfg.gsub! /^(set communityname = ) \S+/, '\\1 <removed>'
    cfg
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].map { |line| line.delete("\r").rstrip }.join("\n") + "\n"
  end

  # 处理软件版本信息
  cmd 'swversion' do |cfg|
    comment cfg
  end

  # 处理插槽信息
  cmd 'slots' do |cfg|
    comment cfg
  end

  # 处理卡信息
  cmd 'eeshow card' do |cfg|
    comment cfg
  end

  # 处理以太网环保护信息，只保留厂商信息
  cmd 'ethrpshow' do |cfg|
    cfg = cfg.each_line.select do |line|
      line.match /Vendor (Name|OUI|Part|Revision)|Serial Number|Manufacturing Date/
    end.join
    comment cfg
  end

  # 处理控制台转储，移除操作提示
  cmd 'dump console' do |cfg|
    cfg.each_line.reject { |line| line.match /To Abort the operation enter Ctrl-C/ }.join
  end

  # Telnet 连接配置
  # zhone technically supports ssh, but it locks up a ton.  Especially when
  # showing large amounts of output, like "dump console"
  cfg :telnet do
    username /\r*login:/
    password /\r*password:/
    pre_logout 'logout'
  end
end
