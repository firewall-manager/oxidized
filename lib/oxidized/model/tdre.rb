# TDRE 设备模型
# 支持 TDRE 网络设备的配置备份
class TDRE < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 TDRE 设备提示符
  prompt /^>$/
  # 获取配置文件的命令
  cmd "get -f"

  # 检查是否为 SSH 连接
  def ssh
    @input.class.to_s.match(/SSH/)
  end

  # 处理提示符，SSH 连接时发送回车符
  expect /^>.+$/ do |data, re|
    send "\r" if ssh
    data.sub re, ''
  end

  # 处理所有命令的输出，根据连接类型调整行数
  cmd :all do |cfg|
    if ssh
      cfg.lines.to_a[5..-4].join
    else
      cfg.lines.to_a[1..-4].join
    end
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    pre_logout "DISCONNECT\r"
  end
end
