# Grandstream 设备模型
# 支持 Grandstream 网络设备的配置备份
# 通过 HTTP API 获取设备配置
class GrandStream < Oxidized::Model
  using Refinements

  # 通过 HTTP 登录并获取配置
  # 使用设备密码进行身份验证，获取会话 ID
  cmd "/cgi-bin/dologin?password=%<password>s" do |cfg| # rubocop:disable Style/FormatStringToken
    # 解析 JSON 响应获取会话 ID
    sid = JSON.parse(cfg)["body"]["sid"]
    # 使用会话 ID 下载配置
    cmd "/cgi-bin/download_cfg?sid=#{sid}"
  end

  # HTTP 连接配置
  # 使用 HTTP 协议而非 SSH/Telnet
  cfg :http do
  end
end
