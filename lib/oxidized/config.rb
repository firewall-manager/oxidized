module Oxidized
  require 'asetus'
  # 配置缺失异常
  class NoConfig < OxidizedError; end
  # 配置无效异常
  class InvalidConfig < OxidizedError; end

  # 配置类
  # 负责加载和管理Oxidized的所有配置选项
  class Config
    # 配置根目录
    ROOT       = ENV['OXIDIZED_HOME'] || File.join(Dir.home, '.config', 'oxidized')
    # 崩溃文件目录
    CRASH      = File.join(ENV['OXIDIZED_LOGS'] || ROOT, 'crash')
    # 日志文件目录
    LOG        = File.join(ENV['OXIDIZED_LOGS'] || ROOT, 'logs')
    # 输入模块目录
    INPUT_DIR  = File.join Directory, %w[lib oxidized input]
    # 输出模块目录
    OUTPUT_DIR = File.join Directory, %w[lib oxidized output]
    # 模型模块目录
    MODEL_DIR  = File.join Directory, %w[lib oxidized model]
    # 源模块目录
    SOURCE_DIR = File.join Directory, %w[lib oxidized source]
    # 钩子模块目录
    HOOK_DIR   = File.join Directory, %w[lib oxidized hook]
    # 主循环睡眠时间
    SLEEP      = 1

    # 加载配置
    # 设置默认配置值，加载用户配置，处理命令行选项
    # @param cmd_opts [Hash] 命令行选项
    # @return [Asetus] 配置对象
    def self.load(cmd_opts = {})
      usrdir = File.expand_path(cmd_opts[:home_dir] || Oxidized::Config::ROOT)
      cfgfile = cmd_opts[:config_file] || 'config'
      # 配置文件完整路径作为类实例变量
      @configfile = File.join(usrdir, cfgfile)
      asetus = Asetus.new(name: 'oxidized', load: false, usrdir: usrdir, cfgfile: cfgfile)
      Oxidized.asetus = asetus

      # 设置默认配置值
      asetus.default.username      = 'username'
      asetus.default.password      = 'password'
      asetus.default.model         = 'junos'
      asetus.default.resolve_dns   = true # 如果为false，不解析DNS到IP
      asetus.default.interval      = 3600
      asetus.default.debug         = false
      asetus.default.run_once      = false
      asetus.default.threads       = 30
      asetus.default.use_max_threads = false
      asetus.default.timeout       = 20
      asetus.default.timelimit     = 300
      asetus.default.retries       = 3
      asetus.default.prompt        = /^([\w.@-]+[#>]\s?)$/
      asetus.default.next_adds_job = false            # 如果为true，/next添加任务，立即获取设备
      asetus.default.vars          = {}               # 可以是'enable'=>'enablePW'
      asetus.default.groups        = {}               # 组级别配置
      asetus.default.group_map     = {}               # 将组的别名映射到名称
      asetus.default.models        = {}               # 模型级别配置
      asetus.default.pid           = File.join(Oxidized::Config::ROOT, 'pid')

      # 扩展配置
      asetus.default.extensions['oxidized-web'].load = false

      asetus.default.crash.directory = File.join(Oxidized::Config::ROOT, 'crashes')
      asetus.default.crash.hostnames = false

      asetus.default.stats.history_size = 10
      asetus.default.input.default      = 'ssh, telnet'
      asetus.default.input.debug        = false # 或字符串用于会话日志文件
      asetus.default.input.ssh.secure   = false # 对更改的证书发出警告
      asetus.default.input.ftp.passive  = true  # ftp被动模式
      asetus.default.input.utf8_encoded = true  # 配置是utf8编码或ascii-8bit

      asetus.default.output.default = 'file'  # file, git
      asetus.default.source.default = 'csv'   # csv, sql

      # 模型映射配置
      asetus.default.model_map = {
        'juniper' => 'junos',
        'cisco'   => 'ios'
      }

      begin
        asetus.load # 加载系统+用户配置，合并到Config.cfg
      rescue StandardError => e
        raise InvalidConfig, "Error loading config: #{e.message}"
      end

      raise NoConfig, "edit #{@configfile}" if asetus.create

      # 如果给出命令行标志则覆盖
      asetus.cfg.debug = cmd_opts[:debug] if cmd_opts[:debug]

      asetus
    end

    class << self
      # 配置文件路径
      attr_reader :configfile
    end
  end

  class << self
    # 全局管理器和钩子对象
    attr_accessor :mgr, :hooks
  end
end
