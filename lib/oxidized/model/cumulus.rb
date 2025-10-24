# Cumulus Linux 设备模型
# 支持 Cumulus Linux 网络操作系统的配置备份
class Cumulus < Oxidized::Model
  using Refinements

  # 正则表达式说明：
  # ^                 : 匹配行开始，以获得最具体的提示符
  # [\w.-]+@[\w.-]+   : 用户@主机名
  # (:mgmt)?          : 带外登录时的可选部分
  # :~[#$] $          : 提示符结束，包含 Linux 路径，
  #                     在我们的上下文中总是 "~"
  prompt /^[\w.-]+@[\w.-]+(:mgmt)?:~[#$] $/
  # 清理转义代码
  clean :escape_codes
  # 注释字符：Cumulus Linux 使用井号作为注释
  comment '# '

  # 在最终配置中添加注释
  # @param comment [String] 注释内容
  # @return [String] 格式化的注释
  def add_comment(comment)
    "\n###### #{comment} ######\n"
  end

  # 处理所有命令的输出，移除首尾行
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理敏感信息，隐藏密码
  cmd :secret do |cfg|
    cfg.gsub! /password (\S+)/, 'password <hidden>'
    cfg
  end

  # 显示持久化配置
  pre do
    use_nclu = vars(:cumulus_use_nclu) || false
    use_nvue = vars(:cumulus_use_nvue) || false

    if use_nclu
      # 使用 NCLU (Network Command Line Utility) 获取配置
      cfg = cmd 'net show configuration commands'
    elsif use_nvue
      # 使用 NVUE (NVUE Configuration) 获取配置
      cfg = cmd 'nv config show --color off'
    else
      # 在配置中设置 FRR 或 Quagga
      routing_daemon = vars(:cumulus_routing_daemon) ? vars(:cumulus_routing_daemon).downcase : 'quagga'
      routing_conf_file = routing_daemon == 'frr' ? 'frr.conf' : 'Quagga.conf'
      routing_daemon_shout = routing_daemon.upcase

      # 主机名
      cfg = add_comment 'THE HOSTNAME'
      cfg += cmd 'cat /etc/hostname'

      # 主机文件
      cfg += add_comment 'THE HOSTS'
      cfg += cmd 'cat /etc/hosts'

      # 网络接口
      cfg += add_comment 'THE INTERFACES'
      cfg += cmd 'grep -r "" /etc/network/interface* | cut -d "/" -f 4-'

      # DNS 解析配置
      cfg += add_comment 'RESOLV.CONF'
      cfg += cmd 'cat /etc/resolv.conf'

      # NTP 配置
      cfg += add_comment 'NTP.CONF'
      cfg += cmd 'cat /etc/ntp.conf'

      # SNMP 设置
      cfg += add_comment 'SNMP settings'
      cfg += cmd 'cat /etc/snmp/snmpd.conf'

      # 路由守护进程
      cfg += add_comment "#{routing_daemon_shout} DAEMONS"
      cfg += cmd "cat /etc/#{routing_daemon}/daemons"

      # Zebra 配置
      cfg += add_comment "#{routing_daemon_shout} ZEBRA"
      cfg += cmd "cat /etc/#{routing_daemon}/zebra.conf"

      # BGP 配置
      cfg += add_comment "#{routing_daemon_shout} BGP"
      cfg += cmd "cat /etc/#{routing_daemon}/bgpd.conf"

      # OSPF 配置
      cfg += add_comment "#{routing_daemon_shout} OSPF"
      cfg += cmd "cat /etc/#{routing_daemon}/ospfd.conf"

      # OSPF6 配置
      cfg += add_comment "#{routing_daemon_shout} OSPF6"
      cfg += cmd "cat /etc/#{routing_daemon}/ospf6d.conf"

      # 路由配置
      cfg += add_comment "#{routing_daemon_shout} CONF"
      cfg += cmd "cat /etc/#{routing_daemon}/#{routing_conf_file}"

      # 登录消息
      cfg += add_comment 'MOTD'
      cfg += cmd 'cat /etc/motd'

      # 用户账户
      cfg += add_comment 'PASSWD'
      cfg += cmd 'cat /etc/passwd'

      # 交换机守护进程配置
      cfg += add_comment 'SWITCHD'
      cfg += cmd 'cat /etc/cumulus/switchd.conf'

      # 端口配置
      cfg += add_comment 'PORTS'
      # 在某些配置中，ports.conf 没有尾随换行符，
      # 这会破坏提示符，所以我们添加一个
      cfg += cmd "cat /etc/cumulus/ports.conf; echo"

      # 流量配置
      cfg += add_comment 'TRAFFIC'
      cfg += cmd 'cat /etc/cumulus/datapath/traffic.conf'

      # 访问控制列表
      cfg += add_comment 'ACL'
      cfg += cmd 'cat /etc/cumulus/acl/policy.conf'

      # DHCP 中继
      cfg += add_comment 'DHCP-RELAY'
      cfg += cmd 'cat /etc/default/isc-dhcp-relay'

      # 版本信息
      cfg += add_comment 'VERSION'
      cfg += cmd 'cat /etc/cumulus/etc.replace/os-release'

      # 许可证信息
      cfg += add_comment 'License'
      cfg += cmd 'cl-license'
    end

    cfg
  end

  # Telnet 连接配置
  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  # Telnet 和 SSH 连接配置
  cfg :telnet, :ssh do
    post_login do
      if vars(:enable) == true
        # 使用 sudo 切换到 root
        cmd "sudo su -", /^\[sudo\] password/
        cmd @node.auth[:password]
      elsif vars(:enable)
        # 使用 su 切换到 root
        cmd "su -", /^Password:/
        cmd vars(:enable)
      end
    end

    pre_logout do
      # 如果启用了特权模式，先退出 su
      cmd "exit" if vars(:enable)
    end
    # 退出 shell
    pre_logout 'exit'
  end
end
