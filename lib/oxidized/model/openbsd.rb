# OpenBSD 设备模型
# 支持 OpenBSD 系统的配置备份
class Openbsd < Oxidized::Model
  using Refinements

  # OpenBSD 自定义提示符，如 user@hostname:~$
  # 您可以编辑用户使用的提示符，对于 root 用户，可以使用 /root/.profile 中的下一个 PS1 定义
  # export PS1="\033[32m\u@\h\033[00m:\033[36m\w\033[00m$ "

  # 提示符正则表达式：匹配 OpenBSD 设备提示符
  prompt /^.+@.+:.+\$/
  # 注释字符：OpenBSD 使用井号作为注释
  comment '# '

  # 在文件/配置之间添加注释
  def add_comment(comment)
    "\n+++++++++++++++++++++++++++++++++++++++++ #{comment} ++++++++++++++++++++++++++++++++++++++++++++++\n"
  end

  # 添加小注释
  def add_small_comment(comment)
    "\n=============== #{comment} ===============\n"
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  # 执行显示命令
  pre do
    # 主机名文件
    cfg = add_comment('HOSTNAME FILE')
    cfg += cmd('cat /etc/myname')

    # DNS 解析配置文件
    cfg += add_comment('RESOLV.CONF FILE')
    cfg += cmd('cat /etc/resolv.conf')

    # NTP 配置文件
    cfg += add_comment('NTP.CONF FILE')
    cfg += cmd('cat /etc/ntp.conf')

    # PF 防火墙配置文件
    cfg += add_comment('PF FILE')
    cfg += cmd('cat /etc/pf.conf')

    # 主机文件
    cfg += add_comment('HOSTS FILE')
    cfg += cmd('cat /etc/hosts')

    # 网络接口文件
    cfg += add_comment('INTERFACE FILES')
    cfg += cmd('tail -n +1 /etc/hostname.*')

    # SNMP 配置文件
    cfg += add_comment('SNMP FILE')
    cfg += cmd('cat /etc/snmpd.conf')

    # 登录消息文件
    cfg += add_comment('MOTD FILE')
    cfg += cmd('cat /etc/motd')

    # 用户密码文件
    cfg += add_comment('PASSWD FILE')
    cfg += cmd('cat /etc/passwd')

    # BGP 守护进程配置文件
    cfg += add_comment('BGPD FILE')
    cfg += cmd('cat /etc/bgpd.conf')

    # OSPF 守护进程配置文件
    cfg += add_comment('OSPFD FILE')
    cfg += cmd('cat /etc/ospfd.conf')

    # OSPF6 守护进程配置文件
    cfg += add_comment('OSPF6D FILE')
    cfg += cmd('cat /etc/ospf6d.conf')

    # 结束标记
    cfg += add_small_comment('END')
    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    # 退出命令
    pre_logout 'exit'
  end
end
