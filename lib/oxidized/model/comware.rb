# Comware 设备模型
# 支持 HP (A-series)/H3C/3Com Comware 网络设备的配置备份
class Comware < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 Comware 设备提示符
  # 有时提示符可能有前导空字符或尾随 ASCII 响铃符 (^G)
  prompt /^\0*(<[\w.-]+>).?$/
  # 注释字符：Comware 使用井号作为注释
  comment '# '

  # 处理分页器的示例
  # expect /^\s*---- More ----$/ do |data, re|
  #  send ' '
  #  data.sub re, ''
  # end

  # 处理所有命令的输出
  cmd :all do |cfg|
    # cfg.gsub! /^.*\e\[42D/, ''        # 处理分页器的示例
    # 跳过流氓 ^M 字符
    cfg = cfg.delete "\r"
    cfg.cut_both
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏 SNMP 代理社区字符串
    cfg.gsub! /^( snmp-agent community).*/, '\\1 <configuration removed>'
    # 隐藏密码哈希
    cfg.gsub! /^( password hash).*/, '\\1 <configuration removed>'
    # 隐藏密码密文
    cfg.gsub! /^( password cipher).*/, '\\1 <configuration removed>'
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^(Username|[Ll]ogin):/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 处理启用密码
    post_login do
      if vars(:enable) == true
        # 启用超级用户模式（无需密码）
        cmd "super"
      elsif vars(:enable)
        # 启用超级用户模式（需要密码）
        cmd "super", /^\s?[pP]assword:/
        cmd vars(:enable)
      end
    end
    # 在 SMB Comware 交换机上启用命令行模式（HP V1910, V1920）
    # 自动检测很困难，因为 'summary' 命令是分页的，
    # 分页器在 _cmdline-mode on 之前无法禁用
    if vars :comware_cmdline
      post_login do
        # HP V1910, V1920
        cmd '_cmdline-mode on', /(#{@node.prompt}|Continue)/
        cmd 'y', /(#{@node.prompt}|input password)/
        cmd vars(:comware_cmdline)

        # HP V1950 r2432P06
        cmd 'xtd-cli-mode on', /(#{@node.prompt}|Continue)/
        cmd 'y', /(#{@node.prompt}|input password)/
        cmd vars(:comware_cmdline)

        # HP V1950 OS r3208 (v7.1)
        # HPE Office Connect 1950
        cmd 'xtd-cli-mode', /(#{@node.prompt}|Continue|Switch)/
        cmd 'y', /(#{@node.prompt}|input password|Password:)/
        cmd vars(:comware_cmdline)
      end
    end

    # 禁用屏幕长度
    post_login 'screen-length disable'
    # 撤销终端监控
    post_login 'undo terminal monitor'
    # 退出命令
    pre_logout 'quit'
  end

  # 处理版本信息
  cmd 'display version' do |cfg|
    # 过滤掉运行时间信息
    cfg = cfg.each_line.reject { |l| l.match /uptime/i }.join
    comment cfg
  end

  # 处理设备信息
  cmd 'display device' do |cfg|
    comment cfg
  end

  # 处理设备制造信息
  cmd 'display device manuinfo' do |cfg|
    # 过滤掉十六进制字符
    cfg = cfg.each_line.reject { |l| l.match 'FF'.hex.chr }.join
    comment cfg
  end

  # 处理当前配置
  cmd 'display current-configuration' do |cfg|
    cfg
  end
end
