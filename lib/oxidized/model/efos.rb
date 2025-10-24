# Enhanced Fabric OS 设备模型
# 支持 Broadcom Enhanced Fabric OS 网络设备的配置备份
class EFOS < Oxidized::Model
  using Refinements

  # Enhanced Fabric OS - Broadcom
  # 注释字符：EFOS 使用感叹号作为注释
  comment '! '
  # 提示符正则表达式：匹配 EFOS 设备提示符
  prompt /^([\w.@()-]+[#>]\s?)$/

  # 处理所有命令的输出
  cmd :all do |cfg|
    # Remove the echo of the entered command and the prompt after it
    cfg.cut_both
  end

  # 处理启动变量信息
  cmd 'show bootvar' do |cfg|
    comment cfg
  end

  # 处理光纤端口光收发器信息
  cmd 'show fiber-ports optical-transceiver-info all' do |cfg|
    comment cfg
  end

  # 处理运行配置，移除时间信息
  cmd 'show running-config' do |cfg|
    cfg.each_line
       .reject { |line| line.match(/System Up Time/) }
       .reject { |line| line.match(/Current System Time:/) }
       .reject { |line| line.match(/Current SNTP Synchronized Time:/) }
       .join
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login do
      if vars(:enable) == true
        cmd 'enable'
      elsif vars(:enable)
        cmd 'enable', /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    post_login 'terminal length 0'
    pre_logout 'logout'
  end
end
