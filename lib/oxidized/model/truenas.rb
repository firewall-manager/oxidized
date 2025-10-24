# TrueNAS 设备模型
# 支持 TrueNAS 网络存储设备的配置备份
class TrueNAS < Oxidized::Model
  using Refinements

  # 注释字符：TrueNAS 使用井号作为注释
  comment '# '

  # 处理系统信息
  cmd('uname -a') { |cfg| comment cfg }
  
  # 处理版本信息
  cmd('cat /etc/version') { |cfg| comment cfg }
  
  # 处理数据库配置
  cmd('sqlite3 "file:///data/freenas-v1.db?mode=ro&immutable=1" .dump') do |cfg|
    # 过滤掉存储复制和系统告警信息
    cfg.lines.reject do |line|
      line.match(/^INSERT INTO storage_replication /) ||
        line.match(/^INSERT INTO system_alert /) || # 忽略数据库中的系统告警
        line.match(/^INSERT INTO sqlite_sequence VALUES\('system_alert',/) # 忽略数据库中的系统告警
    end.join
  end

  # SSH 连接配置
  cfg :ssh do
    # 不运行 shell，在 exec 通道中运行每个命令
    exec true
  end

  # SSH 连接配置
  cfg :ssh do
    # 退出命令
    pre_logout 'exit'
  end
end
