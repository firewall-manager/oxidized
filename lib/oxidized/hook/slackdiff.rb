require 'slack_ruby_client'
require 'uri'
require 'net/http'

# Slack差异钩子模块
# 默认发布差异信息，如果提供了消息格式，则也会发布消息
# diff默认为true

class SlackDiff < Oxidized::Hook
  # 验证配置参数
  # 检查必需的配置项是否存在
  def validate_cfg!
    raise KeyError, 'hook.token is required' unless cfg.has_key?('token')
    raise KeyError, 'hook.channel is required' unless cfg.has_key?('channel')
  end

  # 上传文件到Slack
  # @param client [Slack::Web::Client] Slack客户端
  # @param title [String] 文件标题
  # @param content [String] 文件内容
  # @param channel [String] 频道ID
  # @param proxy [String, nil] 代理设置
  def slack_upload(client, title, content, channel, proxy)
    logger.info "Posting diff as snippet to #{channel}"
    upload_dest = client.files_getUploadURLExternal(filename:     "change",
                                                    length:       content.length,
                                                    snippet_type: "diff")
    file_uri = URI.parse(upload_dest[:upload_url])

    proxy_uri = URI.parse(proxy) if proxy
    proxy_address = proxy_uri ? proxy_uri.host : :ENV
    proxy_port = proxy_uri&.port
    proxy_user = proxy_uri&.user
    proxy_pass = proxy_uri&.password

    http = Net::HTTP.new(file_uri.host, file_uri.port, proxy_address, proxy_port, proxy_user, proxy_pass)
    http.use_ssl = true

    request = Net::HTTP::Post.new(file_uri.request_uri, { Host: file_uri.host })
    request.body = content
    response = http.request(request)

    raise 'Slack file upload failed' unless response.is_a? Net::HTTPSuccess

    files = [{
      id:    upload_dest[:file_id],
      title: title
    }]
    begin
      client.files_completeUploadExternal(channel_id: channel,
                                          files:      files.to_json)
    rescue Slack::Web::Api::Errors::NotInChannel
      logger.info "Not in specified channel, attempting to join"
      client.conversations_join(channel: channel)
      client.files_completeUploadExternal(channel_id: channel,
                                          files:      files.to_json)
    end
  end

  # 运行钩子
  # 将配置差异发送到Slack频道
  # @param ctx [Object] 钩子上下文，包含事件和节点信息
  def run_hook(ctx)
    return unless ctx.node
    return unless ctx.event.to_s == "post_store"

    logger.info "Connecting to slack"
    Slack::Web::Client.configure do |config|
      config.token = cfg.token
      config.proxy = cfg.proxy if cfg.has_key?('proxy')
    end
    client = Slack::Web::Client.new
    client.auth_test
    logger.info "Connected"
    
    # 发布差异信息（如果启用）
    if cfg.has_key?("diff") ? cfg.diff : true
      gitoutput = ctx.node.output.new
      diff = gitoutput.get_diff ctx.node, ctx.node.group, ctx.commitref, nil
      unless diff == "no diffs"
        title = "#{ctx.node.name} #{ctx.node.group} #{ctx.node.model.class.name.to_s.downcase}"
        content = diff[:patch].lines.to_a[4..-1].join
        slack_upload(client, title, content, cfg.channel, cfg.has_key?('proxy') ? cfg.proxy : nil)
      end
    end
    
    # 发布自定义消息（可选）
    if cfg.message?
      logger.info cfg.message
      msg = cfg.message % { node: ctx.node.name.to_s, group: ctx.node.group.to_s, commitref: ctx.commitref,
                            model: ctx.node.model.class.name.to_s.downcase }
      logger.info msg
      logger.info "Posting message to #{cfg.channel}"
      client.chat_postMessage(channel: cfg.channel, text: msg, as_user: true)
    end
    logger.info "Finished"
  end
end
