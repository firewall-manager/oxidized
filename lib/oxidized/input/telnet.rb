module Oxidized
  require 'net/telnet'
  require 'oxidized/input/cli'
  
  # Telnet输入模块
  # 通过Telnet协议连接到设备并执行命令获取配置
  # 适用于支持Telnet协议的传统网络设备
  class Telnet < Input
    # 错误处理配置（当前为空，可根据需要添加Telnet特定错误）
    RESCUE_FAIL = {}.freeze
    include Input::CLI  # 包含CLI通用功能

    # Telnet连接对象
    attr_reader :telnet

    # 连接到Telnet服务器
    # @param node [Node] 要连接的节点对象
    # @return [Boolean] 连接是否成功
    def connect(node) # rubocop:disable Naming/PredicateMethod
      @node    = node
      @timeout = @node.timeout
      # 执行模型中定义的Telnet配置回调
      @node.model.cfg['telnet'].each { |cb| instance_exec(&cb) }
      # 如果启用调试模式，创建日志文件记录Telnet操作
      @log = File.open(Oxidized::Config::LOG + "/#{@node.ip}-telnet", 'w') if Oxidized.config.input.debug?
      port = vars(:telnet_port) || 23  # 默认Telnet端口23

      # 创建Telnet连接选项
      telnet_opts = {
        'Host'    => @node.ip,      # 目标主机IP
        'Port'    => port.to_i,     # Telnet端口
        'Timeout' => @timeout,     # 连接超时
        'Model'   => @node.model,   # 设备模型
        'Log'     => @log           # 日志文件
      }

      @telnet = Net::Telnet.new telnet_opts
      begin
        login
      rescue Timeout::Error
        raise PromptUndetect, ['unable to detect prompt:', @node.prompt].join(' ')
      end
      connected?
    end

    # 检查Telnet连接是否仍然活跃
    # @return [Boolean] 连接是否活跃
    def connected?
      @telnet && (not @telnet.sock.closed?)
    end

    # 执行Telnet命令
    # @param cmd_str [String] 要执行的命令
    # @param expect [Regexp] 期望的提示符正则表达式
    # @return [String] 命令输出
    def cmd(cmd_str, expect = @node.prompt)
      logger.debug "Telnet: #{cmd_str} @#{@node.name}"
      return send(cmd_str + "\r\n") unless expect

      # 创建一个字符串传递给oxidized_expect并在那里修改
      # 默认为单个空格，这样它不应该被任何模型强制转换为nil
      out = String(' ')
      @telnet.puts(cmd_str)
      @telnet.oxidized_expect(timeout: @timeout, expect: expect, out: out)
      out
    end

    # 发送数据到Telnet连接
    # @param data [String] 要发送的数据
    def send(data)
      @telnet.write data
    end

    # 获取Telnet输出
    # @return [String] 输出内容
    def output
      @telnet.output
    end

    private

    # 等待匹配指定的正则表达式
    # @param regex [Regexp] 要匹配的正则表达式
    # @return [Regexp, nil] 匹配的正则表达式或nil
    def expect(regex)
      @telnet.oxidized_expect expect: regex, timeout: @timeout
    end

    # 断开Telnet连接
    def disconnect
      disconnect_cli
      @telnet.close
    rescue Errno::ECONNRESET, IOError
      # 这个异常是有意的，因此不在这里处理
    ensure
      @log.close if Oxidized.config.input.debug?
      (@telnet.close rescue true) unless @telnet.sock.closed? # rubocop:disable Style/RedundantParentheses
    end
  end
end

# 扩展Net::Telnet类以支持Oxidized特定的功能
module Net
  class Telnet
    # 如何在不重新定义整个东西的情况下做到这一点
    # FIXME: 我们还需要输出（不确定我是否会支持这个）
    attr_reader :output

    # Oxidized特定的expect方法
    # 处理Telnet协议的特殊字符和命令
    # @param options [Hash] 选项哈希，包含expect、timeout等
    # @return [Regexp, nil] 匹配的正则表达式或nil
    def oxidized_expect(options)
      model    = @options["Model"]  # 设备模型
      @log     = @options["Log"]    # 日志文件

      expects  = [options[:expect]].flatten  # 期望的正则表达式数组
      time_out = options[:timeout] || @options["Timeout"]  # 超时时间

      Timeout.timeout(time_out) do
        line = ""  # 当前行
        rest = ""  # 剩余数据
        buf  = ""  # 缓冲区
        loop do
          c = @sock.readpartial(1024 * 1024)  # 读取数据
          @output = c
          c = rest + c

          # 处理Telnet协议的特殊字符
          if Integer(c.rindex(/#{IAC}#{SE}/no) || 0) <
             Integer(c.rindex(/#{IAC}#{SB}/no) || 0)
            buf = preprocess(c[0...c.rindex(/#{IAC}#{SB}/no)])
            rest = c[c.rindex(/#{IAC}#{SB}/no)..-1]
          elsif (pt = c.rindex(/#{IAC}[^#{IAC}#{AO}#{AYT}#{DM}#{IP}#{NOP}]?\z/no) ||
                     c.rindex(/\r\z/no))
            buf = preprocess(c[0...pt])
            rest = c[pt..-1]
          else
            buf = preprocess(c)
            rest = ''
          end
          
          # 如果启用调试模式，记录到日志文件
          if Oxidized.config.input.debug?
            @log.print buf
            @log.flush
          end
          
          line += buf
          line = model.expects line  # 让模型处理输出
          # match是一个正则表达式对象。我们需要返回它以便登录工作
          match = expects.find { |re| line.match re }
          # 如果我们有一个out字符串对象，就替换它（因此我们被cmd调用？）
          options[:out]&.replace(line)
          return match if match
        end
      end
    end
  end
end
