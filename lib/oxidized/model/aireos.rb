# AireOS 设备模型
# 支持 AireOS 网络设备的配置备份
# 用于 Cisco WLC 5500 无线控制器
class Aireos < Oxidized::Model
  using Refinements

  # 注释字符：AireOS 使用井号作为注释
  comment '# '
  # 提示符正则表达式：匹配 AireOS 设备提示符
  prompt /^\([^)]+\)\s>/

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理 UDI 信息
  cmd 'show udi' do |cfg|
    cfg = comment clean cfg
    cfg << "\n"
  end

  # 处理启动信息
  cmd 'show boot' do |cfg|
    cfg = comment clean cfg
    cfg << "\n"
  end

  # 处理运行配置命令
  cmd 'show run-config commands' do |cfg|
    clean cfg
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    username /^User:\s*/
    password /^Password:\s*/
    # 禁用配置分页
    post_login 'config paging disable'
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    pre_logout do
      send "logout\n"
      send "n"
    end
  end

  # 清理配置输出
  # @param cfg [String] 配置字符串
  # @return [String] 清理后的配置
  def clean(cfg)
    out = []
    cfg.each_line do |line|
      # 跳过空行
      next if line =~ /^\s*$/
      # 跳过流氓设备信息
      next if line =~ /rogue (adhoc|client) (alert|Unknown) [\da-f]{2}:/

      # 移除回车符
      line = line[1..-1] if line[0] == "\r"
      out << line.strip
    end
    out = out.join "\n"
    out << "\n"
  end
end
