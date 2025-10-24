# Ubiquiti EdgeSwitch 设备模型
# 支持 Ubiquiti EdgeSwitch 系列交换机的配置备份
class EdgeSwitch < Oxidized::Model
  using Refinements

  # 注释字符：EdgeSwitch 使用感叹号作为注释
  comment '!'

  # 提示符正则表达式：匹配 EdgeSwitch 设备提示符
  prompt /\(.*\)\s[#>]/

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    # 移除前两行和后两行，并过滤掉系统运行时间和 SNTP 时间信息
    cfg.each_line.to_a[2..-2].reject do |line|
      line.match(/System Up Time.*/) || line.match(/Current SNTP Synchronized Time.*/)
    end.join
  end

  # Telnet 连接配置
  cfg :telnet do
    username /User(name)?:\s?/
    password /^Password:\s?/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login do
      if vars(:enable) == true
        # 启用特权模式（无需密码）
        cmd "enable"
      elsif vars(:enable)
        # 启用特权模式（需要密码）
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
      # 设置终端长度
      cmd 'terminal length 0'
    end
    # 退出命令
    pre_logout 'quit'
    pre_logout 'n'
  end
end
