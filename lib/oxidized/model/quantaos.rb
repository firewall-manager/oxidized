# Quanta OS 设备模型
# 支持 Quanta OS 网络设备的配置备份
class QuantaOS < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 Quanta OS 设备提示符
  prompt /^\(\S+\) (>|#)$/
  # 注释字符：Quanta OS 使用感叹号作为注释
  comment '! '

  # 处理所有命令的输出，移除命令回显和提示符
  cmd :all do |cfg|
    # Remove command echo and prompt
    cfg.cut_both
  end

  # 处理运行配置，移除注释行
  cmd 'show run' do |cfg|
    # Remove commented lines
    cfg.lines.grep_v(/^!/).join
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^User(name)?:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login do
      send "enable\n"
      cmd vars(:enable) || ""
    end
    post_login 'terminal length 0'
    pre_logout do
      send "quit\n"
      send "n\n"
    end
  end
end
