# OPNsense 设备模型
# 支持 OPNsense 防火墙的配置备份
class OpnSense < Oxidized::Model
  using Refinements

  # 最低所需权限："System: Shell account access"
  # 必须启用 SSH 和基于密码的 SSH 访问

  # 处理配置文件
  cmd 'cat /conf/config.xml' do |cfg|
    # 移除修订时间信息
    cfg.gsub! /\s<revision>\s*<time>\d*<\/time>\s*.*\s*.*\s*<\/revision>/, ''
    # 移除最后规则更新时间信息
    cfg.gsub! /\s<last_rule_upd_time>\d*<\/last_rule_upd_time>/, ''
    cfg
  end

  # 注释输出必须在最后，因为 XML 文件不能以注释开头

  # 使用 opnsense-version 命令获取版本，或从
  # /usr/local/opnsense/version/opnsense 文件获取早期版本的 OPNsense
  # 这些版本缺少 opnsense-version 命令。新版本的 OPNsense 不再
  # 在此文件中存储版本信息，因此现在必须支持两个版本
  cmd 'opnsense-version || echo "OPNsense "`cat /usr/local/opnsense/version/opnsense`' do |version|
    xmlcomment version
  end

  # SSH 连接配置
  cfg :ssh do
    # 在 exec 通道中运行命令
    exec true
    # 退出命令
    pre_logout 'exit'
  end
end
