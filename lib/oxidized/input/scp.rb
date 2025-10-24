module Oxidized
  require 'net/ssh'
  require 'net/scp'
  require 'timeout'
  require_relative 'cli'

  # SCP输入模块
  # 通过SSH协议使用SCP（Secure Copy Protocol）从设备获取配置文件
  # 适用于支持SSH和SCP协议且配置文件可通过SCP访问的设备
  class SCP < Input
    # 错误处理配置
    RESCUE_FAIL = {
      debug: [
        Net::SSH::Disconnect,        # SSH连接断开
        Net::SSH::ConnectionTimeout   # SSH连接超时
      ],
      warn:  [
        Net::SCP::Error,             # SCP操作错误
        Net::SSH::HostKeyUnknown,    # 未知主机密钥
        Net::SSH::AuthenticationFailed,  # SSH认证失败
        Timeout::Error               # 超时错误
      ]
    }.freeze
    include Input::CLI  # 包含CLI通用功能

    # 连接到SCP服务器
    # @param node [Node] 要连接的节点对象
    # @return [Boolean] 连接是否成功
    def connect(node) # rubocop:disable Naming/PredicateMethod
      @node = node
      # 执行模型中定义的SCP配置回调
      @node.model.cfg['scp'].each { |cb| instance_exec(&cb) }
      # 如果启用调试模式，创建日志文件记录SCP操作
      @log = File.open(Oxidized::Config::LOG + "/#{@node.ip}-scp", 'w') if Oxidized.config.input.debug?
      # 建立SSH连接
      @ssh = Net::SSH.start(@node.ip, @node.auth[:username], make_ssh_opts)
      connected?
    end

    # 创建SSH连接选项
    # @return [Hash] SSH连接选项哈希
    def make_ssh_opts
      secure = Oxidized.config.input.scp.secure?
      ssh_opts = {
        number_of_password_prompts:      0,  # 密码提示次数
        verify_host_key:                 secure ? :always : :never,  # 主机密钥验证
        append_all_supported_algorithms: true,  # 添加所有支持的算法
        password:                        @node.auth[:password],  # 认证密码
        timeout:                         @node.timeout,  # 连接超时
        port:                            (vars(:ssh_port) || 22).to_i,  # SSH端口
        forward_agent:                   false  # 不转发SSH代理
      }

      # 使用我们的日志记录器用于Net::SSH
      ssh_logger = SemanticLogger[Net::SSH]
      ssh_logger.level = Oxidized.config.input.debug? ? :debug : :fatal
      ssh_opts[:logger] = ssh_logger

      ssh_opts
    end

    # 检查SSH连接是否仍然活跃
    # @return [Boolean] 连接是否活跃
    def connected?
      @ssh && (not @ssh.closed?)
    end

    # 通过SCP下载文件
    # @param file [String] 要下载的文件路径
    # @return [String] 文件内容
    def cmd(file)
      logger.debug "SCP: #{file} @ #{@node.name}"
      Timeout.timeout(@node.timeout) do
        @ssh.scp.download!(file)
      end
    end

    # 发送数据（对于SCP模块，执行传入的过程）
    # @param my_proc [Proc] 要执行的过程
    def send(my_proc)
      my_proc.call
    end

    # 获取输出（SCP模块不直接支持输出流）
    # @return [String] 空字符串
    def output
      ""
    end

    private

    # 断开SCP连接
    def disconnect
      Timeout.timeout(@node.timeout) do
        @ssh.close
      end
    rescue Timeout::Error
      logger.debug "#{@node.name} timed out while disconnecting"
    ensure
      # 确保关闭日志文件
      @log.close if Oxidized.config.input.debug?
    end
  end
end
