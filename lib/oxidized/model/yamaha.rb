# Yamaha 设备模型
# 支持 Yamaha 网络设备的配置备份
class Yamaha < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 Yamaha 设备提示符
  prompt /^([\w.@()-]+[#>]\s?)$/
  # 注释字符：Yamaha 使用井号作为注释
  comment '# '

  # 处理分页器
  expect /^---more---$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 非首选方式处理额外的密码提示
  # expect /^[\w.]+>$/ do |data|
  #  send "enable\n"
  #  send vars(:enable) + "\n"
  #  data
  # end

  # 处理保存新配置的提示
  expect /^Save new configuration/ do |data, re|
    send "N\n"
    data.sub re, ''
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    # cfg.gsub! /\cH+\s{8}/, ''         # 处理分页器的示例
    # cfg.gsub! /\cH+/, ''              # 处理分页器的示例
    # 移除某些设备上不工作的命令的错误
    cfg.gsub! /^Error: Invalid command name$|^\s+\^$/, ''
    cfg.cut_both
  end

  # 处理配置显示
  cmd 'show config' do |cfg|
    # 移除报告日期信息
    cfg.gsub! /^(# Reporting Date:\s+)(.*)$/, '\1<stripped>'
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    password /^Password:/i
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 处理额外密码的首选方式
    # 设置控制台行数为无限
    post_login 'console lines infinity'
    # 设置控制台列数为 200
    post_login 'console columns  200'
    # 设置控制台字符集为 ASCII
    post_login 'console character ascii'
    post_login do
      # 处理管理员权限
      if vars(:enable) == true
        cmd "administrator"
      elsif vars(:enable)
        cmd "administrator", /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    pre_logout do
      # 退出管理员模式
      cmd 'exit'
    end
    # 退出命令
    pre_logout 'exit'
  end
end
