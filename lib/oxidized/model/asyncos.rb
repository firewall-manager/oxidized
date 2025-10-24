# AsyncOS 设备模型
# 支持 Cisco AsyncOS (Email Security Appliance) 的配置备份
class AsyncOS < Oxidized::Model
  using Refinements

  # ESA prompt "(mail.example.com)> " or "mail.example.com> "
  # 提示符正则表达式：匹配 AsyncOS 设备提示符
  prompt /^\r*\(?[\w.\- ]+\)?[#>]\s+$/
  # 注释字符：AsyncOS 使用感叹号作为注释
  comment '! '

  # 选择密码短语显示选项
  # Select passphrase display option
  expect /\[\S+\]>\s/ do |data, re|
    send "3\n"
    data.sub re, ''
  end

  # 处理分页显示
  # handle paging
  expect /-Press Any Key For More-+.*$/ do |data, re|
    send " "
    data.sub re, ''
  end

  # 处理版本信息
  cmd 'version' do |cfg|
    comment cfg
  end

  # 处理配置显示，清理动态信息和格式化
  cmd 'showconfig' do |cfg|
    # Delete hour and date which change each run
    # cfg.gsub! /\sCurrent Time: \S+\s\S+\s+\S+\s\S+\s\S+/, ' Current Time:'
    # Delete select passphrase display option
    cfg.gsub! "Choose the passphrase option:", ''
    cfg.gsub! /1. Mask passphrases \(Files with masked passphrases cannot be loaded using/, ''
    cfg.gsub! "loadconfig command)", ''
    cfg.gsub! /2. Encrypt passphrases/, ''
    cfg.gsub! /3. Plain passphrases/, ''
    cfg.gsub! /^3$/, ''
    # Delete space
    cfg.gsub! /\n\s{25,26}/, ''
    # Delete after line
    cfg.gsub! /([-\\\/,.\w><@]+)(\s{25,27})/, "\\1"
    # Add a carriage return
    cfg.gsub! /([-\\\/,.\w><@]+)(\s{6})([-\\\/,.\w><@]+)/, "\\1\n\\2\\3"
    # Delete prompt
    cfg.gsub! /^\r*([(][\w. ]+[)][#>]\s+)$/, ''
    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    pre_logout "exit"
  end
end
