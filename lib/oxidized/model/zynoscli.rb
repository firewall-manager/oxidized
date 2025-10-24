# ZynOS CLI 设备模型
# 支持 Zyxel DSLAM 网络设备的配置备份
# 用于 Zyxel DSLAM，如 SAM1316
class ZyNOSCLI < Oxidized::Model
  using Refinements

  # 典型提示符 "XGS4600#"
  # 提示符正则表达式：匹配 ZynOS CLI 设备提示符
  prompt /^([\w.@()-]+[#>]\s\e7)$/
  # 注释字符：ZynOS CLI 使用双分号作为注释
  comment  ';; '

  # 处理所有命令的输出
  cmd :all do |cfg|
    # 移除 ANSI 转义序列
    cfg.gsub! /^.*\e7/, ''
  end

  # 获取堆叠信息
  cmd 'show stacking'

  # 获取版本信息
  cmd 'show version'

  # 获取运行配置
  cmd 'show running-config'

  # Telnet 连接配置
  cfg :telnet do
    username /^User name:/i
    password /^Password:/i
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        # 启用特权模式
        send "enable\n"
        # 将 enable: true 解释为不会提示输入密码
        unless vars(:enable).is_a? TrueClass
          expect /[pP]assword:\s?$/
          send vars(:enable) + "\n"
        end
        # 等待特权模式提示符
        expect /^.+\#$/
      end
    end
    # 退出命令
    pre_logout 'exit'
  end
end
