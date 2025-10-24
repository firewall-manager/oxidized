# Icotera 设备模型
# 支持 Icotera 网络设备的配置备份
class Icotera < Oxidized::Model
  using Refinements

  # 注释字符：Icotera 使用双井号作为注释
  comment '## '

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理管理信息
  cmd 'show management' do |cfg|
    # 隐藏系统运行时间信息
    cfg.gsub! /^\s+System uptime.*\n/, ""
    # 隐藏字节统计信息
    cfg.gsub! /^\s+Bytes in.*\n/, ""
    # 隐藏数据包统计信息
    cfg.gsub! /^\s+Pkts in.*\n/, ""
    # 隐藏单播统计信息
    cfg.gsub! /^\s+Ucast in.*\n/, ""
    # 隐藏广播统计信息
    cfg.gsub! /^\s+Bcast in.*\n/, ""
    # 隐藏组播统计信息
    cfg.gsub! /^\s+Mcast in.*\n/, ""
    # 隐藏单播数据包速率统计
    cfg.gsub! /^\s+Ucast in pps.*\n/, ""
    # 隐藏组播数据包速率统计
    cfg.gsub! /^\s+Mcast in pps.*\n/, ""
    # 隐藏总输入比特率统计
    cfg.gsub! /^\s+Total in bps.*\n/, ""

    comment cfg
  end

  # 复制进度屏幕
  cmd 'copy progress screen'

  # SSH 连接配置
  cfg :ssh do
    # 退出命令
    pre_logout 'exit'
  end
end
