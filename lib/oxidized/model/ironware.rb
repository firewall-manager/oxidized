# Brocade IronWare 设备模型
# 支持 Brocade IronWare 系列交换机的配置备份
class IronWare < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 IronWare 设备提示符
  prompt /^.*(telnet|ssh)@.+[>#]\s?$/i
  # 注释字符：IronWare 使用感叹号作为注释
  comment  '! '

  # 处理分页器而不启用（注释掉的示例）
  # expect /^((.*)--More--(.*))$/ do |data, re|
  #  send ' '
  #  data.sub re, ''
  # end

  # 移除退格符（如果处理分页器而不启用）
  # expect /^((.*)[\b](.*))$/ do |data, re|
  #  data.sub re, ''
  # end

  # 处理所有命令的输出
  cmd :all do |cfg|
    # 有时 IronWare 在 CLI 上发出命令后会插入任意空白字符，
    # 从运行到运行。这标准化了输出。
    cfg.each_line.to_a[1..-2].drop_while { |e| e.match /^\s+$/ }.join
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    # 移除不需要的系统运行时间行
    cfg.gsub! /(^((.*)[Ss]ystem uptime(.*))$)/, ''
    cfg.gsub! /(^((.*)[Tt]he system started at(.*))$)/, ''
    cfg.gsub! /[Uu]p\s?[Tt]ime is .*/, ''

    comment cfg
  end

  # 处理机箱信息
  cmd 'show chassis' do |cfg|
    # 有时 IronWare 返回损坏的编码
    cfg.encode!("UTF-8", invalid: :replace, undef: :replace)
    # 移除不需要的当前温度行
    cfg.gsub! /(^((.*)Current temp(.*))$)/, ''
    # 移除不需要的风扇速度行
    cfg.gsub! /Speed = [A-Z-]{2,6} \(\d{2,3}%\)/, ''
    cfg.gsub! /current speed is [A-Z-]{2,6} \(\d{2,3}%\)/, ''
    # 修复 ADX 风扇速度报告
    cfg.gsub! /Fan \d* - STATUS: OK \D*\d*./, ''
    # 修复 ADX 温度报告
    cfg.gsub! /\d* deg C/, ''
    cfg.gsub! /(\[*)1(\]*)<->(\[*)2(\]*)(<->(\[*)3(\]*))*/, ''
    cfg.gsub! /\d+\.\d deg-C/, 'XX.X deg-C'
    # 处理温度信息
    if cfg.include? "TEMPERATURE"
      sc = StringScanner.new cfg
      out = ''
      temps = ''
      out << sc.scan_until(/.*TEMPERATURE/)
      temps << sc.scan_until(/.*Fans/)
      out << sc.rest
      cfg = out
    end

    comment cfg
  end

  # 处理闪存信息
  cmd 'show flash' do |cfg|
    # 修复 ADX 闪存大小
    cfg.gsub! /(\d+) bytes/, ''
    # Brocade 特定处理
    cfg.gsub! /(^((.*)Code Flash Free Space(.*))$)/, ''
    comment cfg
  end

  # 处理模块信息
  cmd 'show module' do |cfg|
    # 某些 IronWare 设备是固定配置
    cfg.gsub! /^((Invalid input)|(Type \?)).*$/, ''
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    arr = cfg.each_line.to_a
    arr[2..-1].join unless arr.length < 2
  end

  # Telnet 连接配置
  cfg :telnet do
    # 匹配 IronWare 新旧版本的预期提示符
    username /^(Please Enter Login Name|Username):/
    password /^(Please Enter Password ?|Password):/
  end

  # 处理启用分页器
  cfg :telnet, :ssh do
    if vars :enable
      if vars(:enable).is_a? TrueClass
        post_login 'enable'
      else
        post_login do
          send "enable\r\n"
          cmd vars(:enable)
        end
      end
    end
    post_login ''
    # 跳过分页显示
    post_login 'skip-page-display'
    # 设置终端长度
    post_login 'terminal length 0'
    # 退出命令
    pre_logout "logout\nexit\nexit\n"
  end
end
