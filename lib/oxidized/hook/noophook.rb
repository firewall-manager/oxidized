# 空操作钩子模块
# 不执行任何实际操作，仅用于测试和调试目的
class NoopHook < Oxidized::Hook
  # 验证配置参数
  # 空操作钩子不需要验证任何配置
  def validate_cfg!
    logger.info "Validate config"
  end

  # 运行钩子
  # 空操作钩子不执行任何实际操作，仅记录日志
  # @param ctx [Object] 钩子上下文，包含事件和节点信息
  def run_hook(ctx)
    logger.info "Run hook with context: #{ctx}"
  end
end
