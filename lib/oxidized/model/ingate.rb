# Ingate 设备模型
# 支持 Ingate 防火墙的配置备份
class Ingate < Oxidized::Model
  using Refinements

  # 配置回调函数：通过 HTTP POST 获取配置
  cfg_cb = lambda do
    cfg = @m.post(
      @main_url,
      {
        'page'                                      => 'save',
        'db.webgui.testmode/1/timelimit'            => '30',
        'db.webgui.testmode/__KEEP_ROWS_ALIVE'      => '1',
        'db.webgui.pending_apply/1/verbosity'       => 'always',
        'db.webgui.pending_apply/__KEEP_ROWS_ALIVE' => '1',
        'action.admin.download_config_cli'          => 'Save config to CLI file',
        'upload.config_file;filename=type'          => 'application/octet-stream',
        'upload.clicmd_file;filename;type'          => 'application/octet-stream',
        'security'                                  => '',
        'got_complete_form'                         => 'yes'
      },
      'Accept' => 'application/x-config-database'
    )
    cfg.body
  end

  # 处理配置数据
  cmd cfg_cb do |cfg|
    # 移除时间戳信息
    cfg.gsub! /^# Timestamp:.*$/, ''
    cfg
  end

  # HTTP 连接配置
  cfg :http do
    @secure = true
    @main_page = "/"
    # 定义登录方法
    define_singleton_method :login do
      @main_url = URI::HTTP.build host: @node.ip, path: @main_page
      @m.post(
        @main_url,
        {
          'security_user'     => @node.auth[:username],
          'security_password' => @node.auth[:password],
          'page'              => 'login',
          'goal'              => 'save',
          'got_complete_form' => 'yes',
          'security'          => ''
        }
      )
    end
  end
end
