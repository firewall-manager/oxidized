# pfSense 设备模型
# 支持 pfSense 防火墙的配置备份
class PfSense < Oxidized::Model
  using Refinements

  # 使用除 'admin' 用户外的其他用户，'admin' 用户无法获取 ssh/exec 权限。参见 issue #535

  # 处理敏感信息，隐藏密码和哈希值
  cmd :secret do |cfg|
    # 隐藏 bcrypt 哈希值
    cfg.gsub! /(\s+<bcrypt-hash>).+?(<\/bcrypt-hash>)/, '\\1[secret hidden]\\2'
    # 隐藏密码
    cfg.gsub! /(\s+<password>).+?(<\/password>)/, '\\1[secret hidden]\\2'
    # 隐藏 lighttpd 密码
    cfg.gsub! /(\s+<lighttpd_ls_password>).+?(<\/lighttpd_ls_password>)/, '\\1[secret hidden]\\2'
    cfg
  end

  # 处理配置文件
  cmd 'cat /cf/conf/config.xml' do |cfg|
    raise "<pfsense> missing in config file!" unless cfg.include? "<pfsense>"

    # 移除修订时间信息
    cfg.gsub! /\s<revision>\s*<time>\d*<\/time>\s*.*\s*.*\s*<\/revision>/, ''
    # 移除最后规则更新时间信息
    cfg.gsub! /\s<last_rule_upd_time>\d*<\/last_rule_upd_time>/, ''
    # 移除创建时间信息
    cfg.gsub! /\s<created>\s*<time>\d*<\/time>\s*.*CDATA\[Auto\].*\s*.*\s*<\/created>/, ''
    cfg
  end

  # 注释输出必须在最后，因为 XML 文件不能以注释开头

  # 处理版本信息
  cmd 'cat /etc/version' do |version|
    xmlcomment "PFsense #{version}"
  end

  # SSH 连接配置
  cfg :ssh do
    # 在 exec 通道中运行命令
    exec true
    # 退出命令
    pre_logout 'exit'
  end
end
