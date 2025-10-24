# SGOS 设备模型
# 支持 SGOS 网络设备的配置备份
class SGOS < Oxidized::Model
  using Refinements

  # 注释字符：SGOS 使用感叹号-作为注释
  comment '!- '
  # 提示符正则表达式：匹配 SGOS 设备提示符
  prompt /\w+>|#/

  # 处理分页器
  expect /--More--/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    # 移除前三行
    cfg.each_line.to_a[1..-3].join
  end

  # 处理许可证信息
  cmd 'show licenses' do |cfg|
    comment cfg
  end

  # 处理常规信息
  cmd 'show general' do |cfg|
    comment cfg
  end

  # 处理敏感信息，隐藏密码
  cmd :secret do |cfg|
    # 隐藏哈希启用密码
    cfg.gsub! /^(security hashed-enable-password).*/, '\\1 <secret hidden>'
    # 隐藏哈希密码
    cfg.gsub! /^(security hashed-password).*/, '\\1 <secret hidden>'
    cfg
  end

  # 处理扩展配置
  cmd 'show configuration expanded noprompts with-keyrings unencrypted' do |cfg|
    # 移除本地时间信息
    cfg.gsub! /^(!- Local time).*/, ""
    # 移除归档配置加密密码
    cfg.gsub! /^(archive-configuration encrypted-password).*/, ""
    # 移除下载加密密码
    cfg.gsub! /^(download encrypted-password).*/, ""
    cfg
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 处理额外密码的首选方式
    if vars :enable
      post_login do
        # 启用特权模式
        send "enable\n"
        cmd vars(:enable)
      end
    end
    # 退出命令
    pre_logout 'exit'
  end
end
