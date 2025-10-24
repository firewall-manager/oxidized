# APC AOS 设备模型
# 支持 APC (American Power Conversion) AOS 设备的配置备份
class Apc_aos < Oxidized::Model # rubocop:disable Naming/ClassAndModuleCamelCase
  using Refinements

  # 处理配置文件
  cmd 'config.ini' do |cfg|
    # 移除配置文件生成时间信息
    cfg.gsub!(/^; Configuration file, generated on.*\n/, '')
    cfg
  end

  # FTP 和 SCP 连接配置
  cfg :ftp, :scp do
  end
end
