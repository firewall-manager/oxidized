# Cisco Viptela 设备模型
# 支持 Cisco Viptela 网络设备的配置备份
class Viptela < Oxidized::Model
  using Refinements

  # Cisco Vipetla

  # 提示符正则表达式：匹配 Viptela 设备提示符
  prompt /[-\w]+#\s$/
  # 注释字符：Viptela 使用感叹号作为注释
  comment  '! '

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  # 处理敏感信息，隐藏密钥和密码
  cmd :secret do |cfg|
    cfg.gsub! /(^\s+secret-key|password|auth-password|priv-password)\s+.*$/, '\\1 <secret hidden>'
    cfg.gsub! /(^\s+community)\s.*$/, '\\1 <secret hidden>'
    cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # SSH 连接配置
  cfg :ssh do
    post_login 'paginate false'
    pre_logout 'exit'
  end
end
