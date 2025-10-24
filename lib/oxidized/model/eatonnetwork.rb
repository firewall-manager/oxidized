# Eaton Network 设备模型
# 支持 Eaton Gigabit Network Card M3 的配置备份
class EatonNetwork < Oxidized::Model
  using Refinements

  # -p 选项是用于加密配置数据部分的密码短语，
  # 加密数据是非确定性的，每次运行都会改变。使用认证密码作为密码短语。
  #
  # 参见 docs/Model-Notes/EatonNetwork.md 获取更多信息
  post do
    # 在 post 中获取配置以允许将认证密码传递给命令
    cfg = cmd "save_configuration -p #{@node.auth[:password]}"
    cfg
  end

  # 处理所有命令的输出
  cmd :all do |cfg|
    # `save_configuration` 回显命令，输出日期时间信息，
    # 最后一行是提示符
    json_str = cfg.each_line.select { |line| line.match /^\{/ }.join
    json = JSON.parse(json_str)

    # 清理预定义账户信息
    json['features']['userAndSessionManagement']['data']['settings']['all']['1.0']['local']['1.0']['predefinedAccounts'].each do |n|
      n.delete('attemptLogin')
      n['password'].delete('history')
    end
    # 清理创建的账户信息
    json['features']['userAndSessionManagement']['data']['settings']['all']['1.0']['local']['1.0']['createdAccounts'].each do |n|
      n.delete('attemptLogin')
      n['password'].delete('history')
    end

    cfg = JSON.pretty_generate(json)
    cfg
  end

  # 处理敏感信息，隐藏密码和密钥
  cmd :secret do |cfg|
    # 重新解析 JSON 以通过 JSON 路径移除密钥
    json = JSON.parse(cfg)

    # 删除密码短语
    json.delete('passphrase')
    # 删除 RMS 代理用户名和密码
    json['features']['rms']['data']['settings'].delete('proxyUsername')
    json['features']['rms']['data']['settings'].delete('proxyPassword')
    json['features']['rms']['data']['settings'].delete('username')
    json['features']['rms']['data']['settings'].delete('password')
    json['features']['rms']['data']['settings'].delete('defaultPassword')

    # 删除 SMTP 密码
    json['features']['smtp']['data']['dmeData'].delete('password')

    # 删除 SNMP v3 用户密码
    json['features']['snmp']['data']['dmeData']['v3']['users'].each do |n|
      n['auth'].delete('password')
      n['priv'].delete('password')
    end

    # 删除 LDAP 绑定密码
    json['features']['userAndSessionManagement']['data']['settings']['all']['1.0']['ldap']['1.0']['settings']['connectivity']['bind'].delete('password')
    # 删除 RADIUS 服务器密钥
    json['features']['userAndSessionManagement']['data']['settings']['all']['1.0']['radius']['1.0']['settings']['connectivity']['primaryServer'].delete('secret')
    json['features']['userAndSessionManagement']['data']['settings']['all']['1.0']['radius']['1.0']['settings']['connectivity']['secondaryServer'].delete('secret')

    # 在固件 v2.2.0 中添加
    # 删除 802.1x PEAP 密码
    json['features']['peripherals']['data']['dmeData']['ethernet']['ports'].each do |n|
      n.dig('dot1x', 'peap', 'password') && n['dot1x']['peap'].delete('password')
    end

    cfg = JSON.pretty_generate(json)
    cfg
  end

  # SSH 连接配置
  cfg :ssh do
    exec true
    # 退出命令
    pre_logout 'logout'
  end
end
