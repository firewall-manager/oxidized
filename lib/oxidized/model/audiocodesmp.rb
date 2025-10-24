# AudioCodes MediaPack 设备模型
# 支持 AudioCodes MediaPack MP1xx 和 Mediant 1000 设备（固件 v4.xx, v5.xx, v6.xx）的配置备份
class AudioCodesMP < Oxidized::Model
  using Refinements

  # AudioCodes MediaPack MP1xx and Mediant 1000 devices (firmware v4.xx, v5.xx, v6.xx) by pedjajks@gmail.com

  # 提示符正则表达式：匹配 AudioCodes MediaPack 设备提示符
  prompt /^\/\w*>/

  # 注释字符：AudioCodes MediaPack 使用分号作为注释
  comment ';'

  # 进入配置模式
  cmd 'conf' do
  end

  # 获取配置文件，清理垃圾数据
  cmd 'cf get' do |cfg|
    lines = cfg.each_line.to_a[0..-1]
    # remove any garbage before ';**************' and after '; End of INI file.'
    lines[lines.index(";**************\r\n")..lines.index("; End of INI file.\n")].join
  end

  # SSH 连接配置
  cfg :ssh do
    username /^login as:\s$/
    password /^.+password:\s$/
    pre_logout 'exit'
  end

  # Telnet 连接配置
  cfg :telnet do
    username /login:\s$/
    password /password:\s$/
    pre_logout 'exit'
  end
end
