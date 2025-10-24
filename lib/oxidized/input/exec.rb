module Oxidized
  require "oxidized/input/cli"

  # 执行输入模块
  # 通过本地执行命令来获取设备配置
  # 适用于可以通过本地命令直接访问设备配置的场景
  class Exec < Input
    include Input::CLI  # 包含CLI通用功能

    # 连接到节点（对于Exec模块，实际上是初始化配置）
    # @param node [Node] 要连接的节点对象
    def connect(node)
      @node = node
      # 如果启用调试模式，创建日志文件记录执行过程
      @log = File.open(Oxidized::Config::LOG + "/#{@node.ip}-exec", "w") if Oxidized.config.input.debug?
      # 执行模型中定义的exec配置回调
      @node.model.cfg["exec"].each { |cb| instance_exec(&cb) }
    end

    # 执行命令并返回结果
    # @param cmd_str [String] 要执行的命令字符串
    # @return [String] 命令执行结果
    def cmd(cmd_str)
      logger.debug "EXEC: #{cmd_str} @ #{@node.name}"
      # 使用系统命令执行，返回标准输出
      # 注意：理想情况下应该使用popen3并分别处理参数，
      # 但这需要重构cmd方法来接受参数
      %x(#{cmd_str})
    end

    private

    # 断开连接（对于Exec模块，实际上只是清理资源）
    # @return [Boolean] 总是返回true
    def disconnect
      true
    ensure
      # 确保关闭日志文件
      @log.close if Oxidized.config.input.debug?
    end
  end
end
