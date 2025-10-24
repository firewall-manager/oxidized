require 'semantic_logger'

module Oxidized
  # 命令行接口类
  # 处理Oxidized的命令行参数、进程管理和启动逻辑
  class CLI
    include SemanticLogger::Loggable

    require 'slop'
    require 'oxidized'
    require 'English'

    # 运行Oxidized主程序
    # 检查PID文件、处理守护进程模式、写入PID文件并启动核心程序
    def run
      check_pid
      Process.daemon if @opts[:daemonize]
      write_pid
      begin
        logger.info "Oxidized starting, running as pid #{$PROCESS_ID}"
        Oxidized.new
      rescue StandardError => e
        crash e
        raise
      end
    end

    private

    # 初始化命令行接口
    # 解析命令行参数、加载配置、设置日志和PID文件路径
    def initialize
      _args, @opts = parse_opts

      Config.load(@opts)
      Oxidized::Logger.setup

      @pidfile = File.expand_path(Oxidized.config.pid)
    end

    # 处理程序崩溃
    # 将崩溃信息写入崩溃文件
    # @param error [Exception] 异常对象
    def crash(error)
      logger.fatal "Oxidized crashed, crashfile written in #{Config::CRASH}"
      File.open Config::CRASH, 'w' do |file|
        file.puts '-' * 50
        file.puts Time.now.utc
        file.puts error.message + ' [' + error.class.to_s + ']'
        file.puts '-' * 50
        file.puts error.backtrace
        file.puts '-' * 50
      end
    end

    # 解析命令行选项
    # @return [Array] [参数数组, 选项对象]
    def parse_opts
      opts = Slop.parse do |opt|
        opt.on '-d', '--debug', 'turn on debugging'
        opt.on '--daemonize', 'Daemonize/fork the process'
        opt.string '--home-dir', 'Oxidized home dir', default: nil
        opt.string '--config-file', 'Oxidized config file', default: nil
        opt.on '-h', '--help', 'show usage' do
          puts opt
          exit
        end
        opt.on '--show-exhaustive-config', 'output entire configuration, including defaults' do
          asetus = Config.load
          puts asetus.to_yaml asetus.cfg
          Kernel.exit
        end
        opt.on '-v', '--version', 'show version' do
          puts Oxidized::VERSION_FULL
          Kernel.exit
        end
      end
      [opts.arguments, opts]
    end

    # PID文件路径
    attr_reader :pidfile

    # 检查是否有PID文件
    # @return [Boolean] 是否有PID文件
    def pidfile?
      !!pidfile
    end

    # 写入PID文件
    # 创建PID文件并注册退出时清理
    def write_pid
      return unless pidfile?

      begin
        File.open(pidfile, ::File::CREAT | ::File::EXCL | ::File::WRONLY) { |f| f.write(Process.pid.to_s) }
        at_exit { FileUtils.rm_f(pidfile) }
      rescue Errno::EEXIST
        check_pid
        retry
      end
    end

    # 检查PID文件状态
    # 检查是否有其他实例在运行
    def check_pid
      return unless pidfile?

      case pid_status(pidfile)
      when :running, :not_owned
        puts "A server is already running. Check #{pidfile}"
        exit(1)
      when :dead
        File.delete(pidfile)
      end
    end

    # 检查PID文件状态
    # @param pidfile [String] PID文件路径
    # @return [Symbol] PID状态：:running, :dead, :not_owned, :exited
    def pid_status(pidfile)
      return :exited unless File.exist?(pidfile)

      pid = ::File.read(pidfile).to_i
      return :dead if pid.zero?

      Process.kill(0, pid)
      :running
    rescue Errno::ESRCH
      :dead
    rescue Errno::EPERM
      :not_owned
    end
  end
end
