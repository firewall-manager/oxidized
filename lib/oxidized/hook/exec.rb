# 执行钩子模块
# 在Oxidized事件发生时执行外部命令，支持同步和异步执行
class Exec < Oxidized::Hook
  include Process

  # 初始化执行钩子
  def initialize
    super
    @timeout = 60
    @async = false
  end

  # 验证配置参数
  # 检查超时、异步和命令配置的有效性
  def validate_cfg!
    # 语法检查
    if cfg.has_key? "timeout"
      @timeout = cfg.timeout
      raise "invalid timeout value" unless @timeout.is_a?(Integer) &&
                                           @timeout.positive?
    end

    @async = !!cfg.async if cfg.has_key? "async"

    if cfg.has_key? "cmd"
      @cmd = cfg.cmd
      raise "invalid cmd value" unless @cmd.is_a?(String) || @cmd.is_a?(Array)
    end
  rescue RuntimeError => e
    raise ArgumentError,
          "#{self.class.name}: configuration invalid: #{e.message}"
  end

  # 运行钩子
  # 执行配置的外部命令
  # @param ctx [Object] 钩子上下文，包含事件和节点信息
  def run_hook(ctx)
    env = make_env ctx
    logger.debug "Execute: #{@cmd.inspect}"
    th = Thread.new do
      run_cmd! env
    rescue StandardError => e
      raise e unless @async
    end
    th.join unless @async
  end

  # 执行命令
  # @param env [Hash] 环境变量哈希
  def run_cmd!(env)
    pid = nil
    status = nil
    Timeout.timeout(@timeout) do
      pid = spawn env, @cmd, unsetenv_others: true
      pid, status = wait2 pid
      unless status.exitstatus.zero?
        msg = "#{@cmd.inspect} failed with exit value #{status.exitstatus}"
        logger.error msg
        raise msg
      end
    end
  rescue Timeout::Error
    kill "TERM", pid
    msg = "#{@cmd} timed out"
    logger.error msg
    raise Timeout::Error, msg
  end

  # 创建环境变量
  # 将钩子上下文信息转换为环境变量
  # @param ctx [Object] 钩子上下文
  # @return [Hash] 环境变量哈希
  def make_env(ctx)
    env = {
      "OX_EVENT" => ctx.event.to_s
    }
    if ctx.node
      env.merge!(
        "OX_NODE_NAME"      => ctx.node.name.to_s,
        "OX_NODE_IP"        => ctx.node.ip.to_s,
        "OX_NODE_FROM"      => ctx.node.from.to_s,
        "OX_NODE_MSG"       => ctx.node.msg.to_s,
        "OX_NODE_GROUP"     => ctx.node.group.to_s,
        "OX_NODE_MODEL"     => ctx.node.model.class.name,
        "OX_REPO_COMMITREF" => ctx.commitref.to_s,
        "OX_REPO_NAME"      => ctx.node.repo.to_s,
        "OX_ERR_TYPE"       => ctx.node.err_type.to_s,
        "OX_ERR_REASON"     => ctx.node.err_reason.to_s
      )
    end
    if ctx.job
      env["OX_JOB_STATUS"] = ctx.job.status.to_s
      env["OX_JOB_TIME"] = ctx.job.time.to_s
    end
    env
  end
end
