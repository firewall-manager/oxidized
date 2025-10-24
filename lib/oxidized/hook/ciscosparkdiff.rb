require 'cisco_spark'

# Cisco Spark差异钩子模块
# 默认发布差异信息，如果提供了消息格式，则也会发布消息
# diff默认为true
# 从slackdiff修改而来

class CiscoSparkDiff < Oxidized::Hook
  # 验证配置参数
  # 检查必需的配置项是否存在
  def validate_cfg!
    raise KeyError, 'hook.accesskey is required' unless cfg.has_key?('accesskey')
    raise KeyError, 'hook.space is required' unless cfg.has_key?('space')
  end

  # 运行钩子
  # 将配置差异发送到Cisco Spark空间
  # @param ctx [Object] 钩子上下文，包含事件和节点信息
  def run_hook(ctx)
    return unless ctx.node
    return unless ctx.event.to_s == "post_store"

    logger.info "Connecting to Cisco Spark"
    CiscoSpark.configure do |config|
      config.api_key = cfg.accesskey
      config.proxy = cfg.proxy if cfg.has_key?('proxy')
    end
    room = CiscoSpark::Room.new(id: cfg.space)
    logger.info "Connected"

    # 发布差异信息（如果启用）
    if cfg.has_key?("diff") ? cfg.diff : true
      gitoutput = ctx.node.output.new
      diff = gitoutput.get_diff ctx.node, ctx.node.group, ctx.commitref, nil
      title = ctx.node.name.to_s
      logger.info "Posting diff as snippet to #{cfg.space}"
      room.send_message CiscoSpark::Message.new(text: "Device #{title} modified:\n" +
                                                      diff[:patch].lines.to_a[4..-1].join)
    end

    # 发布自定义消息（如果配置了）
    if cfg.message?
      logger.info cfg.message
      msg = cfg.message % { node: ctx.node.name.to_s, group: ctx.node.group.to_s, commitref: ctx.commitref,
                            model: ctx.node.model.class.name.to_s.downcase }
      logger.info msg
      logger.info "Posting message to #{cfg.space}"
      room.send_message CiscoSpark::Message.new(text: msg)
    end

    logger.info "Finished"
  end
end
