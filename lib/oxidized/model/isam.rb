# Alcatel ISAM 设备模型
# 支持 Alcatel ISAM 7302/7330 FTTN 设备的配置备份
class ISAM < Oxidized::Model
  using Refinements

  # Alcatel ISAM 7302/7330 FTTN

  # 提示符正则表达式：匹配 ISAM 设备提示符
  prompt /^([\w.:@-]+>#\s)$/
  # 注释字符：ISAM 使用井号作为注释
  comment '# '

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^login:\s*/
    password /^password:\s*/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login 'environment prompt "%n># "'
    post_login 'environment mode batch'
    post_login 'environment inhibit-alarms print no-more'
    pre_logout 'logout'
  end

  # 处理软件管理信息
  cmd 'show software-mngt oswp detail' do |cfg|
    comment cfg
  end

  # 处理设备插槽详细信息
  cmd 'show equipment slot detail' do |cfg|
    comment cfg
  end

  # 处理配置信息
  cmd 'info configure flat' do |cfg|
    cfg
  end
end
