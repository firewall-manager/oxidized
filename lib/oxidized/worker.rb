module Oxidized
  require 'oxidized/job'
  require 'oxidized/jobs'
  # 工作器类
  # 管理工作线程池，负责调度和执行节点配置获取任务
  class Worker
    include SemanticLogger::Loggable

    # 初始化工作器
    # @param nodes [Nodes] 节点集合对象
    def initialize(nodes)
      @jobs_done  = 0
      @nodes      = nodes
      @jobs       = Jobs.new(Oxidized.config.threads, Oxidized.config.use_max_threads, Oxidized.config.interval, @nodes)
      @nodes.jobs = @jobs
      Thread.abort_on_exception = true
    end

    # 执行工作循环
    # 处理已完成的任务，调度新任务，管理任务队列
    def work
      ended = []
      @jobs.delete_if { |job| ended << job unless job.alive? }
      ended.each      { |job| process job }
      @jobs.work

      while @jobs.size < @jobs.want
        logger.debug "Jobs running: #{@jobs.size} of #{@jobs.want} - ended: " \
                     "#{@jobs_done} of #{@nodes.size}"
        # 以非破坏性方式询问队列中的下一个节点
        nextnode = @nodes.first
        unless nextnode.last.nil?
          # 如果禁用了间隔检查，为'last'设置不可获得的值
          last = Oxidized.config.interval.zero? ? Time.now.utc + 10 : nextnode.last.end
          break if last + Oxidized.config.interval > Time.now.utc
        end
        # 移动节点并获取下一个节点
        node = @nodes.get
        node.running? ? next : node.running = true

        @jobs.push Job.new node
        logger.debug "Added #{node.group}/#{node.name} to the job queue"
      end

      if cycle_finished?
        run_done_hook
        exit 0 if Oxidized.config.run_once
      end
      logger.debug("#{@jobs.size} jobs running in parallel") unless @jobs.empty?
    end

    # 处理已完成的任务
    # 更新节点统计信息，处理成功或失败的任务
    # @param job [Job] 已完成的任务
    def process(job)
      node = job.node
      node.last = job
      node.stats.add job
      @jobs.duration job.time
      node.running = false
      if job.status == :success
        process_success node, job
      else
        process_failure node, job
      end
    rescue NodeNotFound
      logger.warn "#{node.group}/#{node.name} not found, removed while collecting?"
    end

    # 重新加载节点列表
    def reload
      @nodes.load
    end

    private

    # 处理成功的任务
    # 存储配置，触发钩子，重置节点状态
    # @param node [Node] 节点对象
    # @param job [Job] 任务对象
    def process_success(node, job)
      @jobs_done += 1 # 为:nodes_done钩子所需
      Oxidized.hooks.handle :node_success, node: node,
                                           job:  job
      msg = "update #{node.group}/#{node.name}"
      msg += " from #{node.from}" if node.from
      msg += " with message '#{node.msg}'" if node.msg
      output = node.output.new
      if output.store node.name, job.config,
                      msg: msg, email: node.email, user: node.user, group: node.group
        node.modified
        logger.info "Configuration updated for #{node.group}/#{node.name}"
        Oxidized.hooks.handle :post_store, node:      node,
                                           job:       job,
                                           commitref: output.commitref
      end
      node.reset
    end

    # 处理失败的任务
    # 处理重试逻辑或放弃任务
    # @param node [Node] 节点对象
    # @param job [Job] 任务对象
    def process_failure(node, job)
      msg = "#{node.group}/#{node.name} status #{job.status}"
      if node.retry < Oxidized.config.retries
        node.retry += 1
        msg += ", retry attempt #{node.retry}"
        @nodes.next node.name
      else
        # 只有在放弃节点重试（或成功）时才增加@jobs_done
        # 否则会导致@jobs_done因通用重试而增加
        # 这会导致:nodes_done钩子在节点列表末尾运行时不同步
        # 并在@jobs_done > @nodes.count时触发（可能在下一个周期的中期）
        @jobs_done += 1
        msg += ", retries exhausted, giving up"
        node.retry = 0
        Oxidized.hooks.handle :node_fail, node: node,
                                          job:  job
      end
      logger.warn msg
    end

    # 检查周期是否完成
    # @return [Boolean] 是否完成一个周期
    def cycle_finished?
      @jobs_done > @nodes.count ||
        (@jobs_done.positive? && (@jobs_done % @nodes.count).zero?)
    end

    # 运行完成钩子
    # 触发:nodes_done钩子并重置计数器
    def run_done_hook
      logger.debug "Running :nodes_done hook"
      Oxidized.hooks.handle :nodes_done
    rescue StandardError => e
      # 吞下钩子错误并正常继续
      logger.error e.message
    ensure
      @jobs_done = 0
    end
  end
end
