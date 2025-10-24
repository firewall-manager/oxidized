module Oxidized
  # 任务类
  # 继承自Thread，用于在独立线程中执行节点配置获取任务
  class Job < Thread
    include SemanticLogger::Loggable

    # 任务属性：开始时间、结束时间、状态、耗时、节点、配置
    attr_reader :start, :end, :status, :time, :node, :config

    # 初始化任务
    # 在独立线程中执行节点配置获取
    # @param node [Node] 要处理的节点对象
    def initialize(node)
      @node = node
      @start = Time.now.utc
      self.name = "Job '#{@node.name}'"
      super do
        logger.debug "Starting fetching process for #{@node.name}"
        begin
          Timeout.timeout(Oxidized.config.timelimit) do
            @status, @config = @node.run
          end
          logger.debug "Config fetched for #{@node.name}"
        rescue Timeout::Error
          logger.warn "Job timelimit reached for #{@node.name}"
          @status = :timelimit
        ensure
          @end  = Time.now.utc
          @time = @end - @start
        end
      end
    end
  end
end
