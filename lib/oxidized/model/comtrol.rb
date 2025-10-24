# Comtrol 设备模型
# 支持 Comtrol 工业交换机（如 RocketLinx ES8510）的配置备份
class Comtrol < Oxidized::Model
  using Refinements

  # Used in Comtrol Industrial Switches, such as RocketLinx ES8510

  # 提示符正则表达式：匹配 Comtrol 设备提示符
  # Typical prompt "<hostname>#"
  prompt /([#>]\s?)$/
  # 注释字符：Comtrol 使用感叹号作为注释
  comment '! '

  # 处理分页器
  # how to handle pager
  expect /--More--+\s$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^User name:/i
    password /^Password:/i
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        # Interpret enable: true as meaning we won't be prompted for a password
        unless vars(:enable).is_a? TrueClass
          expect /[pP]assword:\s?$/
          send vars(:enable) + "\n"
        end
        expect /^.+\#\s?$/
      end
    end
    pre_logout 'exit'
  end
end
