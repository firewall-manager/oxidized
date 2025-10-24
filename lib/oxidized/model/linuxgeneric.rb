# Linux 通用设备模型
# 支持 Linux 系统的配置备份
class LinuxGeneric < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 Linux shell 提示符
  prompt /^(\w.*|\W.*)[:#$] /
  # 注释字符：Linux 使用井号作为注释
  comment '# '

  # 在最终配置中添加注释
  # @param comment [String] 注释内容
  # @return [String] 格式化的注释
  def add_comment(comment)
    "\n###### #{comment} ######\n"
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    # 隐藏默认路由的过期时间
    cfg.gsub! /^(default (\S+).* (expires) ).*/, '\\1 <redacted>'
    cfg.cut_both
  end

  # 显示持久化配置
  pre do
    # 主机名
    cfg = add_comment 'THE HOSTNAME'
    cfg += cmd 'cat /etc/hostname'

    # 主机文件
    cfg += add_comment 'THE HOSTS'
    cfg += cmd 'cat /etc/hosts'

    # 网络接口
    cfg += add_comment 'THE INTERFACES'
    cfg += cmd 'ip link'

    # DNS 解析配置
    cfg += add_comment 'RESOLV.CONF'
    cfg += cmd 'cat /etc/resolv.conf'

    # IP 路由表
    cfg += add_comment 'IP Routes'
    cfg += cmd 'ip route'

    # IPv6 路由表
    cfg += add_comment 'IPv6 Routes'
    cfg += cmd 'ip -6 route'

    # 登录消息
    cfg += add_comment 'MOTD'
    cfg += cmd 'cat /etc/motd'

    # 用户账户
    cfg += add_comment 'PASSWD'
    cfg += cmd 'cat /etc/passwd'

    # 用户组
    cfg += add_comment 'GROUP'
    cfg += cmd 'cat /etc/group'

    # 名称服务切换配置
    cfg += add_comment 'nsswitch.conf'
    cfg += cmd 'cat /etc/nsswitch.conf'

    # 系统版本信息
    cfg += add_comment 'VERSION'
    cfg += cmd 'cat /etc/issue'

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
