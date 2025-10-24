module Oxidized
  require 'net/ssh'
  require 'net/ssh/proxy/command'
  require 'timeout'
  require 'oxidized/input/cli'
  
  # SSH输入模块
  # 通过SSH协议连接到设备并执行命令获取配置
  # 支持交互式shell和直接命令执行两种模式
  class SSH < Input
    # 错误处理配置
    RESCUE_FAIL = {
      debug: [
        Net::SSH::Disconnect  # SSH连接断开
      ],
      warn:  [
        RuntimeError,                    # 运行时错误
        Net::SSH::AuthenticationFailed   # SSH认证失败
      ]
    }.freeze
    include Input::CLI  # 包含CLI通用功能

    # 无法获取Shell异常类
    class NoShell < OxidizedError; end

    # 连接到SSH服务器
    # @param node [Node] 要连接的节点对象
    # @return [Boolean] 连接是否成功
    def connect(node) # rubocop:disable Naming/PredicateMethod
      @node        = node
      @output      = String.new('')  # 输出缓冲区
      @pty_options = { term: "vt100" }  # PTY终端选项
      # 执行模型中定义的SSH配置回调
      @node.model.cfg['ssh'].each { |cb| instance_exec(&cb) }
      
      # 如果启用调试模式，创建日志文件记录SSH操作
      if Oxidized.config.input.debug?
        logfile = Oxidized::Config::LOG + "/#{@node.ip}-ssh"
        @log = File.open(logfile, 'w')
        logger.debug "I/O Debuging to #{logfile}"
      end

      logger.debug "Connecting to #{@node.name}"
      # 建立SSH连接
      @ssh = Net::SSH.start(@node.ip, @node.auth[:username], make_ssh_opts)
      
      # 除非使用exec模式，否则打开shell并登录
      unless @exec
        shell_open @ssh
        begin
          login
        rescue Timeout::Error
          raise PromptUndetect, [@output, 'not matching configured prompt', @node.prompt].join(' ')
        end
      end
      connected?
    end

    # 检查SSH连接是否仍然活跃
    # @return [Boolean] 连接是否活跃
    def connected?
      @ssh && (not @ssh.closed?)
    end

    # 执行SSH命令
    # @param cmd [String] 要执行的命令
    # @param expect [Regexp] 期望的提示符正则表达式
    # @return [String] 命令输出
    def cmd(cmd, expect = node.prompt)
      logger.debug "Sending '#{cmd.dump}' @ #{node.name} with expect: #{expect.inspect}"
      if Oxidized.config.input.debug?
        @log.puts "sent cmd #{@exec ? cmd.dump : (cmd + newline).dump}"
        @log.flush
      end
      
      # 根据执行模式选择不同的命令执行方式
      cmd_output = if @exec
                     # 直接执行模式：使用SSH exec
                     @ssh.exec! cmd
                   else
                     # 交互式shell模式：使用shell执行
                     cmd_shell(cmd, expect).gsub("\r\n", "\n")
                   end
      # 确保返回字符串类型
      cmd_output.to_s
    end

    # 发送数据到SSH会话
    # @param data [String] 要发送的数据
    def send(data)
      if Oxidized.config.input.debug?
        @log.puts "sent data #{data.dump}"
        @log.flush
      end
      @ses.send_data data
    end

    # 获取输出缓冲区内容
    attr_reader :output

    # 设置PTY选项
    # @param hash [Hash] PTY选项哈希
    def pty_options(hash)
      @pty_options = @pty_options.merge hash
    end

    private

    # 断开SSH连接
    def disconnect
      disconnect_cli
      # 如果断开连接没有成功，在超时后放弃
      Timeout.timeout(@node.timeout) { @ssh.loop }
    rescue Errno::ECONNRESET, Net::SSH::Disconnect, IOError => e
      logger.debug 'The other side closed the connection while ' \
                   "disconnecting, raising #{e.class} with #{e.message}"
    rescue Timeout::Error
      logger.debug "#{@node.name} timed out while disconnecting"
    ensure
      @log.close if Oxidized.config.input.debug?
      (@ssh.close rescue true) unless @ssh.closed? # rubocop:disable Style/RedundantParentheses
    end

    # 打开SSH shell会话
    # @param ssh [Net::SSH::Connection] SSH连接对象
    def shell_open(ssh)
      @ses = ssh.open_channel do |ch|
        # 处理接收到的数据
        ch.on_data do |_ch, data|
          if Oxidized.config.input.debug?
            @log.puts "received #{data.dump}"
            @log.flush
          end
          @output << data
          @output = @node.model.expects @output
        end
        # 请求PTY（伪终端）
        ch.request_pty(@pty_options) do |_ch, success_pty|
          raise NoShell, "Can't get PTY" unless success_pty

          # 请求shell
          ch.send_channel_request 'shell' do |_ch, success_shell|
            raise NoShell, "Can't get shell" unless success_shell
          end
        end
      end
    end

    # 设置或获取exec模式状态
    # @param state [Boolean, nil] 新的exec状态，nil表示获取当前状态
    # @return [Boolean, nil] exec状态
    def exec(state = nil)
      return nil if vars(:ssh_no_exec)

      state.nil? ? @exec : (@exec = state)
    end

    # 在shell中执行命令
    # @param cmd [String] 要执行的命令
    # @param expect_re [Regexp] 期望的提示符正则表达式
    # @return [String] 命令输出
    def cmd_shell(cmd, expect_re)
      @output = String.new('')
      @ses.send_data cmd + newline
      @ses.process
      expect expect_re if expect_re
      @output
    end

    # 等待匹配指定的正则表达式
    # @param regexps [Array<Regexp>] 要匹配的正则表达式数组
    # @return [Regexp, nil] 匹配的正则表达式或nil
    def expect(*regexps)
      regexps = [regexps].flatten
      logger.debug "Expecting #{regexps.inspect} at #{node.name}"
      Timeout.timeout(@node.timeout) do
        @ssh.loop(0.1) do
          sleep 0.1
          match = regexps.find { |regexp| @output.match regexp }
          return match if match

          true
        end
      end
    end

    # 创建SSH连接选项
    # @return [Hash] SSH连接选项哈希
    def make_ssh_opts
      secure = Oxidized.config.input.ssh.secure?
      ssh_opts = {
        number_of_password_prompts:      0,  # 密码提示次数
        keepalive:                       vars(:ssh_no_keepalive) ? false : true,  # 保持连接
        verify_host_key:                 secure ? :always : :never,  # 主机密钥验证
        append_all_supported_algorithms: true,  # 添加所有支持的算法
        password:                        @node.auth[:password],  # 认证密码
        timeout:                         @node.timeout,  # 连接超时
        port:                            (vars(:ssh_port) || 22).to_i,  # SSH端口
        forward_agent:                   false  # 不转发SSH代理
      }

      # 设置认证方法
      auth_methods = vars(:auth_methods) || %w[none publickey password]
      ssh_opts[:auth_methods] = auth_methods
      logger.debug "AUTH METHODS::#{auth_methods}"

      # 设置SSH代理（如果配置了）
      ssh_opts[:proxy] = make_ssh_proxy_command(vars(:ssh_proxy), vars(:ssh_proxy_port), secure) if vars(:ssh_proxy)

      # 设置SSH密钥和算法
      ssh_opts[:keys]       = [vars(:ssh_keys)].flatten           if vars(:ssh_keys)
      ssh_opts[:kex]        = vars(:ssh_kex).split(/,\s*/)        if vars(:ssh_kex)
      ssh_opts[:encryption] = vars(:ssh_encryption).split(/,\s*/) if vars(:ssh_encryption)
      ssh_opts[:host_key]   = vars(:ssh_host_key).split(/,\s*/)   if vars(:ssh_host_key)
      ssh_opts[:hmac]       = vars(:ssh_hmac).split(/,\s*/)       if vars(:ssh_hmac)

      # 使用我们的日志记录器用于Net::SSH
      ssh_logger = SemanticLogger[Net::SSH]
      ssh_logger.level = Oxidized.config.input.debug? ? :debug : :fatal
      ssh_opts[:logger] = ssh_logger

      ssh_opts
    end

    # 创建SSH代理命令
    # @param proxy_host [String] 代理主机
    # @param proxy_port [Integer] 代理端口
    # @param secure [Boolean] 是否安全模式
    # @return [Net::SSH::Proxy::Command, nil] SSH代理命令对象
    def make_ssh_proxy_command(proxy_host, proxy_port, secure)
      return nil unless !proxy_host.nil? && !proxy_host.empty?

      proxy_command =  "ssh "
      proxy_command += "-o StrictHostKeyChecking=no " unless secure
      proxy_command += "-p #{proxy_port} "            if proxy_port
      proxy_command += "#{proxy_host} -W [%h]:%p"
      Net::SSH::Proxy::Command.new(proxy_command)
    end
  end
end
