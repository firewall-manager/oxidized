# GardeROS 设备模型
# 支持 Garderos GmbH 路由器的配置备份
# 用于恶劣环境的路由器
# grs = Garderos Router Software
# https://www.garderos.com/
class Garderos < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 GardeROS 设备提示符
  prompt /[\w-]+# /
  # 清理转义代码
  clean :escape_codes
  # 注释字符：GardeROS 使用井号作为注释
  comment '# '

  # 处理所有命令的输出
  cmd :all do |cfg|
    # 移除输入命令的回显和其后的提示符
    cfg.cut_both
  end

  # 处理系统版本信息
  cmd 'show system version' do |cfg|
    comment "#{cfg}\n"
  end

  # 处理系统序列号信息
  cmd 'show system serial' do |cfg|
    comment "#{cfg}\n"
  end

  # 如果安装了无线电调制解调器，我们希望列出 SIM 卡信息
  cmd 'show hardware wwan wwan0 sim' do |cfg|
    if cfg.start_with? 'Unknown command'
      String.new('')
    else
      comment "#{cfg}\n"
    end
  end

  # 获取运行配置
  cmd 'show configuration running'

  # SSH 连接配置
  cfg :ssh do
    # 退出命令
    pre_logout 'exit'
  end
end
