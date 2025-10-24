# Cambium 设备模型
# 支持 Cambium 无线设备的配置备份
class Cambium < Oxidized::Model
  using Refinements

  # 配置回调函数：通过 Web 界面获取配置文件
  cfg_cb = lambda do
    c_page = @m.click @m_page.link_with(text: "Configuration")
    u_page = @m.click c_page.link_with(text: "Unit Settings")
    cfg    = @m.click u_page.link_with(text: /\.cfg$/)
    cfg.body
  end

  # 处理配置文件，移除时间戳信息
  cmd cfg_cb do |cfg|
    cfg.gsub! /"cfgUtcTimestamp":.*?,\n/, ''
    cfg
  end

  # HTTP 连接配置
  cfg :http do
    @main_page = "/main.cgi"
    define_singleton_method :login do
      @m_page = @m_page.form_with(action: "login.cgi") do |form|
        form.CanopyUsername = @node.auth[:username]
        form.CanopyPassword = @node.auth[:password]
      end.submit
    end
  end
end
