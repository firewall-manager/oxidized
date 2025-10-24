# Palo Alto PAN-OS 设备模型
# 支持 Palo Alto Networks 防火墙的配置备份
class PanOS < Oxidized::Model
  using Refinements

  # 注释字符：PAN-OS 使用感叹号作为注释
  comment '! '

  # 提示符正则表达式：匹配 PAN-OS 设备提示符
  prompt /^[\w.@:()-]+>\s?$/

  # 处理所有命令的输出，移除前两行和后三行
  cmd :all do |cfg|
    cfg.each_line.to_a[2..-3].join
  end

  # 处理系统信息
  cmd 'show system info' do |cfg|
    # 隐藏时间信息
    cfg.gsub! /^(up)?time: .*$/, ''
    # 隐藏应用程序版本信息
    cfg.gsub! /^app-.*?: .*$/, ''
    # 隐藏防病毒版本信息
    cfg.gsub! /^av-.*?: .*$/, ''
    # 隐藏威胁版本信息
    cfg.gsub! /^threat-.*?: .*$/, ''
    # 隐藏 WildFire 版本信息
    cfg.gsub! /^wildfire-.*?: .*$/, ''
    cfg.gsub! /^wf-private.*?: .*$/, ''
    # 隐藏设备字典版本信息
    cfg.gsub! /^device-dictionary-version.*?: .*$/, ''
    cfg.gsub! /^device-dictionary-release-date.*?: .*$/, ''
    # 隐藏 URL 过滤版本信息
    cfg.gsub! /^url-filtering.*?: .*$/, ''
    # 隐藏全局版本信息
    cfg.gsub! /^global-.*?: .*$/, ''
    comment cfg
  end

  # 处理运行配置
  cmd 'show config running' do |cfg|
    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    # 设置 CLI 分页器关闭
    post_login 'set cli pager off'
    # 退出命令
    pre_logout 'quit'
  end
end
