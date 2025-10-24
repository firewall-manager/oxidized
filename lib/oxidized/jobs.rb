module Oxidized
  # 任务队列类
  # 继承自Array，管理任务队列和线程调度
  class Jobs < Array
    # 平均持续时间（秒）- 初始假设节点需要5秒完成
    AVERAGE_DURATION  = 5
    # 最大任务间隔（秒）- 如果超过此时间则添加任务
    MAX_INTER_JOB_GAP = 300
    # 间隔、最大线程数、期望线程数
    attr_accessor :interval, :max, :want

    # 初始化任务队列
    # @param max [Integer] 最大线程数
    # @param use_max_threads [Boolean] 是否使用最大线程数
    # @param interval [Integer] 间隔时间
    # @param nodes [Nodes] 节点集合
    def initialize(max, use_max_threads, interval, nodes)
      @max = max
      @use_max_threads = use_max_threads
      # 如果间隔为0（禁用），设置为1，这样不会破坏'ceil'函数
      @interval = interval.zero? ? 1 : interval
      @nodes = nodes
      @last = Time.now.utc
      @durations = Array.new @nodes.size, AVERAGE_DURATION
      duration AVERAGE_DURATION
      super()
    end

    # 添加任务到队列
    # @param arg [Object] 任务对象
    def push(arg)
      @last = Time.now.utc
      super
    end

    # 更新任务持续时间
    # 维护滚动平均持续时间
    # @param last [Float] 最后任务的持续时间
    def duration(last)
      if @durations.size > @nodes.size
        @durations.slice! @nodes.size...@durations.size
      elsif @durations.size < @nodes.size
        @durations.fill AVERAGE_DURATION, @durations.size...@nodes.size
      end
      @durations.push(last).shift
      @duration = @durations.inject(:+).to_f / @nodes.size # 滚动平均
      new_count
    end

    # 计算新的任务数量
    # 根据配置和节点数量计算期望的线程数
    def new_count
      @want = if @use_max_threads
                @max
              else
                ((@nodes.size * @duration) / @interval).ceil
              end
      @want = 1 if @want < 1
      @want = @nodes.size if @want > @nodes.size
      @want = @max if @want > @max
    end

    # 安全地增加任务数量
    # 在以下条件下增加任务数量：
    # a) 运行的线程数少于节点总数
    # b) 我们想要的线程数少于指定的最大线程数
    def increment
      @want = [(@want + 1), @nodes.size, @max].min
    end

    # 执行工作调度
    # 检查是否需要增加线程数以修复挂起线程导致的头阻塞
    def work
      # 如果满足以下条件：
      # a) 我们想要的线程数少于或等于当前运行的线程数
      # b) 我们想要的线程数少于节点总数
      # c) 自上次启动任务以来超过MAX_INTER_JOB_GAP时间
      # 则增加一个线程（原理是修复导致HOLB的挂起线程）
      return unless @want <= size && @want < @nodes.size

      return unless @want <= size

      increment if (Time.now.utc - @last) > MAX_INTER_JOB_GAP
    end
  end
end
