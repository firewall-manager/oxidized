# OpenWrt 设备模型
# 支持 OpenWrt 网络设备的配置备份
class OpenWrt < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 OpenWrt 设备提示符
  prompt /^[^#]+#/
  # 注释字符：OpenWrt 使用井号作为注释
  comment '#'

  # 处理横幅信息
  cmd 'cat /etc/banner' do |cfg|
    comment "#### Info: /etc/banner #####\n#{cfg}"
  end

  # 处理 CPU 信息
  cmd 'cat /proc/cpuinfo' do |cfg|
    comment "#### Info: /proc/cpuinfo #####\n#{cfg}"
  end

  # 处理 OpenWrt 版本信息
  cmd 'cat /etc/openwrt_release' do |cfg|
    comment "#### Info: /etc/openwrt_release #####\n#{cfg}"
  end

  # 处理系统升级文件列表
  cmd 'sysupgrade -l' do |cfg|
    @sysupgradefiles = cfg
    comment "#### Info: sysupgrade -l #####\n#{cfg}"
  end

  # 处理 MTD 分区信息
  cmd 'cat /proc/mtd' do |cfg|
    @mtdpartitions = cfg
    comment "#### Info: /proc/mtd #####\n#{cfg}"
  end

  # 后处理：导出配置和分区
  post do
    cfg = []
    # 二进制文件列表
    binary_files = vars(:openwrt_binary_files) || %w[/etc/dropbear/dropbear_rsa_host_key]
    # 非敏感文件列表
    non_sensitive_files = vars(:openwrt_non_sensitive_files) || %w[rpcd uhttpd]
    # 要备份的分区列表
    partitions_to_backup = vars(:openwrt_partitions_to_backup) || %w[art devinfo u_env config caldata]
    
    # 处理系统升级文件
    @sysupgradefiles.lines.each do |sysupgradefile|
      sysupgradefile = sysupgradefile.strip
      # 处理配置文件
      if sysupgradefile.start_with?('/etc/config/')
        unless sysupgradefile.end_with?('-opkg')
          filename = sysupgradefile.split('/')[-1]
          cfg << comment("#### File: #{sysupgradefile} #####")
          # 导出 UCI 配置
          uciexport = cmd("uci export #{filename}")
          logger.debug "Exporting uci config - #{filename}"
          # 如果启用了敏感信息移除且不是非敏感文件
          if vars(:remove_secret) && !(non_sensitive_files.include? filename)
            logger.debug "Scrubbing uci config - #{filename}"
            # 隐藏密码和密钥
            uciexport.gsub!(/^(\s+option\s+(password|key)\s+')[^']+'/, '\\1<secret hidden>\'')
          end
          cfg << uciexport
        end
      # 处理二进制文件
      elsif binary_files.include? sysupgradefile
        logger.debug "Exporting binary file - #{sysupgradefile}"
        cfg << comment("#### Binary file: #{sysupgradefile} #####")
        cfg << comment("Decode using 'echo -en <data> | gzip -dc > #{sysupgradefile}'")
        cfg << cmd("gzip -c #{sysupgradefile} | hexdump -ve '1/1 \"_x%.2x\"' | tr _ \\")
      # 处理影子文件（密码文件）
      elsif vars(:remove_secret) && sysupgradefile == '/etc/shadow'
        logger.debug 'Exporting and scrubbing /etc/shadow'
        cfg << comment("#### File: #{sysupgradefile} #####")
        shadow = cmd("cat #{sysupgradefile}")
        # 隐藏密码哈希
        shadow.gsub!(/^([^:]+:)[^:]*(:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:)/, '\\1\\2')
        cfg << shadow
      # 处理普通文件
      else
        logger.debug "Exporting file - #{sysupgradefile}"
        cfg << comment("#### File: #{sysupgradefile} #####")
        cfg << cmd("cat #{sysupgradefile}")
      end
    end
    
    # 处理 MTD 分区
    @mtdpartitions.scan(/(\w+):\s+\w+\s+\w+\s+"(.*)"/).each do |partition, name|
      next unless vars(:openwrt_backup_partitions) && partitions_to_backup.include?(name)

      logger.debug "Exporting partition - #{name}(#{partition})"
      cfg << comment("#### Partition: #{name} /dev/#{partition} #####")
      cfg << comment("Decode using 'echo -en <data> | gzip -dc > #{name}'")
      cfg << cmd("dd if=/dev/#{partition} 2>/dev/null | gzip -c | hexdump -ve '1/1 \"%.2x\"'")
    end
    cfg.join "\n"
  end

  # SSH 连接配置
  cfg :ssh do
    # 在 exec 通道中运行命令
    exec true
    # 退出命令
    pre_logout 'exit'
  end
end
