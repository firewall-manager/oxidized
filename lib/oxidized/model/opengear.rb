# OpenGear 设备模型
# 支持 OpenGear 网络设备的配置备份
class OpenGear < Oxidized::Model
  using Refinements

  # 注释字符：OpenGear 使用井号作为注释
  comment '# '

  # 提示符正则表达式：匹配 OpenGear 设备提示符
  prompt /^(\$\s)$/

  # 处理敏感信息，隐藏各种密码和密钥
  cmd :secret do |cfg|
    cfg.gsub!(/password (\S+)/, 'password <secret removed>')
    cfg.gsub!(/community (\S+)/, 'community <secret removed>')
    cfg.gsub!(/community=(\S+)/, 'community=<secret removed>')
    cfg.gsub!(/private_key=(\S+)/, 'private_key=<secret removed>')
    cfg.gsub!(/ key=(\S+)/, ' key=<secret removed>')
    cfg.gsub!(/hashed_password=(\S+)/, 'hashed_password=<secret removed>')
    cfg
  end

  # 处理版本信息
  cmd('cat /etc/version') { |cfg| comment cfg }

  # 处理设备信息（新版本 OpenGear 固件）
  # newer opengear firmware versions
  cmd 'ogdeviceinfo -r' do |cfg|
    comment cfg unless cfg.include? "ogdeviceinfo: command not found"
  end

  # 处理配置导出
  cmd 'config export' do |cfg|
    unless cfg.include? "usage: config"
      out = ''
      cfg.each_line do |line|
        out << line
      end
      out
    end
  end

  # 处理序列号信息（旧版本 OpenGear 固件）
  # older opengear firmware versions
  cmd 'showserial' do |cfg|
    unless cfg.include? "showserial: command not found"
      cfg.gsub! /^/, 'Serial Number: '
      comment cfg
    end
  end

  # 处理配置信息
  cmd 'config -g config' do |cfg|
    unless cfg.include? "config: error: argument"
      out = ''
      cfg.each_line do |line|
        out << line
      end
      out
    end
  end

  # SSH 连接配置
  cfg :ssh do
    exec true # don't run shell, run each command in exec channel
  end
end
