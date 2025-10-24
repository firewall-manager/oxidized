module Oxidized
  require 'net/ftp'
  require 'timeout'
  require_relative 'cli'

  # FTP输入模块
  # 通过FTP协议从设备获取配置文件
  # 适用于支持FTP协议且配置文件可通过FTP访问的设备
  class FTP < Input
    # 错误处理配置（当前为空，可根据需要添加FTP特定错误）
    RESCUE_FAIL = {
      debug: [
        # Net::SSH::Disconnect,  # SSH断开连接（不适用于FTP）
      ],
      warn:  [
        # RuntimeError,           # 运行时错误
        # Net::SSH::AuthenticationFailed,  # SSH认证失败（不适用于FTP）
      ]
    }.freeze
    include Input::CLI  # 包含CLI通用功能

    # 连接到FTP服务器
    # @param node [Node] 要连接的节点对象
    # @return [Boolean] 连接是否成功
    def connect(node) # rubocop:disable Naming/PredicateMethod
      @node = node
      # 执行模型中定义的FTP配置回调
      @node.model.cfg['ftp'].each { |cb| instance_exec(&cb) }
      # 如果启用调试模式，创建日志文件记录FTP操作
      @log = File.open(Oxidized::Config::LOG + "/#{@node.ip}-ftp", 'w') if Oxidized.config.input.debug?
      
      # 创建FTP连接
      @ftp = Net::FTP.new(@node.ip)
      # 设置被动模式（从配置中读取）
      @ftp.passive = Oxidized.config.input.ftp.passive
      # 使用用户名和密码登录
      @ftp.login @node.auth[:username], @node.auth[:password]
      connected?
    end

    # 检查FTP连接是否仍然活跃
    # @return [Boolean] 连接是否活跃
    def connected?
      @ftp && (not @ftp.closed?)
    end

    # 通过FTP下载文件
    # @param file [String] 要下载的文件路径
    # @return [String] 文件内容
    def cmd(file)
      logger.debug "FTP: #{file} @ #{@node.name}"
      # 使用二进制模式下载文件到内存
      @ftp.getbinaryfile file, nil
    end

    # 发送数据（对于FTP模块，执行传入的过程）
    # 注意：不确定这是最佳实现方式，但比不实现send方法要好
    # @param my_proc [Proc] 要执行的过程
    def send(my_proc)
      my_proc.call
    end

    # 获取输出（FTP模块不直接支持输出流）
    # @return [String] 空字符串
    def output
      ""
    end

    private

    # 断开FTP连接
    def disconnect
      @ftp.close
    # rescue Errno::ECONNRESET, IOError  # 可以捕获连接重置和IO错误
    ensure
      # 确保关闭日志文件
      @log.close if Oxidized.config.input.debug?
    end
  end
end
