module Oxidized
  require 'stringio'
  require_relative 'cli'

  begin
    require 'net/tftp'
  rescue LoadError
    raise OxidizedError, 'net/tftp not found: sudo gem install net-tftp'
  end

  # TFTP输入模块
  # 通过TFTP（Trivial File Transfer Protocol）协议从设备获取配置文件
  # 适用于支持TFTP协议且配置文件可通过TFTP访问的设备
  class TFTP < Input
    include Input::CLI  # 包含CLI通用功能

    # 连接到TFTP服务器
    # TFTP使用UDP协议，没有持久连接。我们只需指定IP地址并发送/接收数据
    # @param node [Node] 要连接的节点对象
    # @return [Boolean] 连接是否成功
    def connect(node)
      @node = node

      # 执行模型中定义的TFTP配置回调
      @node.model.cfg['tftp'].each { |cb| instance_exec(&cb) }
      # 如果启用调试模式，创建日志文件记录TFTP操作
      @log = File.open(Oxidized::Config::LOG + "/#{@node.ip}-tftp", 'w') if Oxidized.config.input.debug?
      # 创建TFTP连接对象
      @tftp = Net::TFTP.new @node.ip
    end

    # 通过TFTP下载文件
    # @param file [String] 要下载的文件路径
    # @return [String] 文件内容
    def cmd(file)
      logger.debug "TFTP: #{file} @ #{@node.name}"
      config = StringIO.new  # 创建字符串IO对象存储文件内容
      @tftp.getbinary file, config  # 使用二进制模式下载文件
      config.rewind  # 重置IO位置到开始
      config.read    # 读取文件内容
    end

    private

    # 断开TFTP连接
    # TFTP使用UDP协议，没有连接需要关闭
    # @return [Boolean] 总是返回true
    def disconnect
      # TFTP使用UDP，没有连接需要关闭
      true
    ensure
      # 确保关闭日志文件
      @log.close if Oxidized.config.input.debug?
    end
  end
end
