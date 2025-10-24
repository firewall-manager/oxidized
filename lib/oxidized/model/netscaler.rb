# Citrix NetScaler 设备模型
# 支持 Citrix NetScaler 负载均衡器的配置备份
class NetScaler < Oxidized::Model
  using Refinements

  # 提示符正则表达式：匹配 NetScaler 设备提示符
  prompt /^(.*[\w.-]*>\s?)$/
  # 注释字符：NetScaler 使用井号作为注释
  comment '# '

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.each_line.to_a[1..-3].join
  end

  # 处理版本信息
  cmd 'show version' do |cfg|
    comment cfg
  end

  # 处理硬件信息
  cmd 'show hardware' do |cfg|
    comment cfg
  end

  # 处理分区信息
  cmd 'show partition' do |cfg|
    comment cfg
  end

  # 处理敏感信息，隐藏加密内容
  cmd :secret do |cfg|
    cfg.gsub! /\w+\s(-encrypted)/, '<secret hidden> \\1'
    cfg
  end

  # 检查是否有多个分区
  # check for multiple partitions
  cmd 'show partition' do |cfg|
    @is_multiple_partition = cfg.include? 'Name:'
  end

  # 后处理：根据分区情况选择处理方式
  post do
    if @is_multiple_partition
      multiple_partition
    else
      single_partition
    end
  end

  # 单分区模式处理
  def single_partition
    # Single partition mode
    cmd 'show ns ns.conf' do |cfg|
      cfg
    end
  end

  # 多分区模式处理
  def multiple_partition
    # Multiple partition mode
    cmd 'show partition' do |cfg|
      allcfg = ""
      partitions = [["default"]] + cfg.scan(/Name: (\S+)$/)
      partitions.each do |part|
        allcfg = allcfg + "\n\n####################### [ partition " + part.join(" ") + " ] #######################\n\n"
        cmd "switch ns partition " + part.join(" ") + "; show ns ns.conf; switch ns partition default" do |cfgpartition|
          allcfg += cfgpartition
        end
      end
      allcfg
    end
  end

  # SSH 连接配置
  cfg :ssh do
    pre_logout 'exit'
  end
end
