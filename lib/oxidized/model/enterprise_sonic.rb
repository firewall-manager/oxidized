# Enterprise SONiC 设备模型
# 支持 Enterprise SONiC 网络设备的配置备份
class Enterprise_SONiC < Oxidized::Model # rubocop:disable Naming/ClassAndModuleCamelCase
  using Refinements

  # 移除 ANSI 转义码
  # Remove ANSI escape codes
  expect /\e\[[0-?]*[ -\/]*[@-~]\r?/ do |data, re|
    data.gsub re, ''
  end

  # 匹配 sonic-cli 和 linux 终端
  # Matches both sonic-cli and linux terminal
  prompt /^(?:[\w.-]+@[\w.-]+:[~\w\/-]+\$|[\w.-]+#)\s*/
  # 注释字符：Enterprise SONiC 使用井号作为注释
  comment "# "

  # 添加注释的方法
  def add_comment(comment)
    "\n##### #{comment} #####\n"
  end

  # 后处理：获取运行配置
  post do
    cmd 'show running-configuration' do |cfg|
      add_comment('CONFIGURATION') + cfg
    end
  end

  # 处理版本信息，移除运行时间
  cmd 'show version' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match /Uptime/ }.join
    add_comment('VERSION') + cfg
  end

  # 处理平台系统 EEPROM 信息
  cmd 'show platform syseeprom' do |cfg|
    add_comment('SYSEEPROM') + cfg
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    cfg.cut_both
  end

  # SSH 连接配置
  cfg :ssh do
    # 如果用户登录到 linux == 有管理员权限
    # if user logs in to linux == has admin rights
    if vars(:admin) == true
      post_login do
        cmd "sonic-cli\n"
      end
    end
    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
