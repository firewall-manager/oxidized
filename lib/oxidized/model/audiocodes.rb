# AudioCodes 设备模型
# 支持 AudioCodes Mediant 设备版本 > 7.0 的配置备份
class AudioCodes < Oxidized::Model
  using Refinements

  # Pull config from AudioCodes Mediant devices from version > 7.0

  # 提示符正则表达式：匹配 AudioCodes 设备提示符
  prompt /^\r?([\w.@() -]+[#>]\s?)$/
  # 注释字符：AudioCodes 使用双井号作为注释
  comment '## '

  # 处理分页显示
  expect /\s*--MORE--$/ do |data, re|
    send ' '

    data.sub re, ''
  end

  # 处理运行配置
  cmd "show running-config\r\n" do |cfg|
    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    username /^login as:\s$/
    password /^.+password:\s$/
    pre_logout "exit\r\n"
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:\s$/
    password /^Password:\s$/
    pre_logout 'exit'
  end
end
