# Check Point GaiaOS 设备模型
# 支持 Check Point Gaia OS 防火墙的配置备份
class GaiaOS < Oxidized::Model
  using Refinements

  # Gaia 提示符正则表达式：匹配 GaiaOS 设备提示符
  prompt /^([\[\]\w.@:-]+[#>]\s?)$/

  # 注释字符：GaiaOS 使用井号作为注释
  comment  '# '

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 隐藏专家密码哈希
    cfg.gsub! /^(set expert-password-hash ).*/, '\1<EXPERT PASSWORD REMOVED>'
    # 隐藏用户密码哈希
    cfg.gsub! /^(set user \S+ password-hash ).*/, '\1<USER PASSWORD REMOVED>'
    # 隐藏 OSPF 密钥
    cfg.gsub! /^(set ospf .* secret ).*/, '\1<OSPF KEY REMOVED>'
    # 隐藏 SNMP 社区字符串
    cfg.gsub! /^(set snmp community )(.*)( read-only.*)/, '\1<SNMP COMMUNITY REMOVED>\3'
    cfg.gsub! /^(add snmp .* community )(.*)(\S?.*)/, '\1<SNMP COMMUNITY REMOVED>\3'
    # 隐藏 SNMP 密码短语
    cfg.gsub! /(auth|privacy)(-pass-phrase-hashed )(\S*)/, '\1-pass-phrase-hashed <SNMP PASS-PHRASE REMOVED>'
    cfg
  end

  # 检查 VSX / 多上下文模式
  cmd 'show vsx' do |cfg|
    @is_vsx = cfg.include? 'VSX Enabled'
    logger.debug cfg
  end

  # 处理资产信息
  cmd 'show asset all' do |cfg|
    comment cfg
  end

  # 处理版本信息
  cmd 'show version all' do |cfg|
    comment cfg
  end

  # 后处理：根据 VSX 模式选择处理方式
  post do
    if @is_vsx
      multiple_context
    else
      single_context
    end
  end

  # 单上下文模式处理
  def single_context
    logger.debug 'Single context tasks'
    cmd 'show configuration' do |cfg|
      # 移除导出信息
      cfg.gsub! /^# Exported by \S+ on .*/, '# '
      cfg
    end
  end

  # 多上下文模式处理
  def multiple_context
    logger.debug 'Multi context tasks'
    cmd 'show virtual-system all' do |systems|
      # 提取虚拟系统信息
      vs_items = systems.scan(/^(?<VSID>\d+)\s+(?<VSNAME>.*[^\s])/)
      allcfg = ''
      # 处理每个虚拟系统
      vs_items.each do |item|
        allcfg += "\n\n\n#--------======== [ VS #{item[0]} - #{item[1]} ] ========--------\n\n"
        allcfg += "set virtual-system #{item[0]}\n\n"
        cmd "set virtual-system #{item[0]}" do |vs|
          logger.debug vs
          cmd 'show configuration' do |vscfg|
            # 移除导出信息
            vscfg.gsub! /^# Exported by \S+ on .*/, '# '
            allcfg += vscfg
          end
        end
      end
      allcfg
    end
  end

  # SSH 连接配置
  cfg :ssh do
    # 用户 shell 必须是 /etc/cli.sh
    post_login 'set clienv rows 0'
    # 退出命令
    pre_logout 'exit'
  end
end
