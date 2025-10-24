require 'aws-sdk'

# AWS SNS钩子模块
# 将Oxidized事件发送到AWS Simple Notification Service (SNS)
class AwsSns < Oxidized::Hook
  # 验证配置参数
  # 检查必需的配置项是否存在
  def validate_cfg!
    raise KeyError, 'hook.region is required' unless cfg.has_key?('region')
    raise KeyError, 'hook.topic_arn is required' unless cfg.has_key?('topic_arn')
  end

  # 运行钩子
  # 将事件信息发送到AWS SNS主题
  # @param ctx [Object] 钩子上下文，包含事件和节点信息
  def run_hook(ctx)
    sns = Aws::SNS::Resource.new(region: cfg.region)
    topic = sns.topic(cfg.topic_arn)
    message = {
      event: ctx.event.to_s
    }
    if ctx.node
      message.merge!(
        group: ctx.node.group.to_s,
        model: ctx.node.model.class.name.to_s.downcase,
        node:  ctx.node.name.to_s
      )
    end
    topic.publish(
      message: message.to_json
    )
  end
end
