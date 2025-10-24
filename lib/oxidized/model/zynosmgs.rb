# ZynOS MGS 设备模型
# 支持 Zyxel MGS 系列交换机的配置备份
class ZyNOSMGS < Oxidized::Model
  using Refinements

  # 提示符正则表达式常量
  PROMPT = /^(\w.*)>(.*)?$/
  
  # 提示符正则表达式：匹配 ZynOS MGS 设备提示符
  prompt PROMPT
  # 注释字符：ZynOS MGS 使用感叹号作为注释
  comment '! '

  # 处理版本信息
  cmd 'show version' do |cfg|
    clear_output cfg
  end

  # 处理运行配置
  cmd 'show running-config' do |cfg|
    clear_output cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^User\s?name(\(1-32 chars\))?:/i
    password /^Password(\(1-32 chars\))?:/i
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 退出命令
    pre_logout 'exit'
  end

  private

  # 清理输出，移除提示符
  def clear_output(output)
    output.gsub PROMPT, ''
  end
end
