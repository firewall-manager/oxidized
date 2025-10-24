# 钩子模块

这个目录包含了 Oxidized 的各种钩子模块，用于在特定事件发生时执行自定义操作。

## 模块说明

### 核心文件
- `awssns.rb` - AWS SNS 钩子模块
- `ciscosparkdiff.rb` - Cisco Spark 钩子模块
- `exec.rb` - 执行命令钩子模块
- `githubrepo.rb` - GitHub 仓库钩子模块
- `noophook.rb` - 空操作钩子模块
- `slackdiff.rb` - Slack 钩子模块
- `xmppdiff.rb` - XMPP 钩子模块

## 钩子系统架构

### 事件类型
Oxidized 支持以下事件类型：
- `node_success` - 节点配置获取成功
- `node_fail` - 节点配置获取失败
- `post_store` - 配置存储完成后
- `nodes_done` - 所有节点处理完成

### 钩子基类
所有钩子模块都继承自 `Oxidized::Hook` 基类：

```ruby
class MyHook < Hook
  def validate_cfg!
    # 验证配置
  end
  
  def run_hook(ctx)
    # 执行钩子逻辑
  end
end
```

### 钩子上下文
钩子接收上下文对象，包含：
- `event` - 事件类型
- `node` - 节点对象
- `job` - 任务对象
- `commitref` - 提交引用

## 钩子模块详解

### AWS SNS 钩子 (awssns.rb)
- **功能**：将事件发送到 AWS SNS 主题
- **特点**：云集成、消息队列、可扩展
- **适用场景**：云环境、大规模部署

```ruby
# 配置示例
hooks:
  aws_sns:
    type: awssns
    events: [node_success, node_fail]
    region: us-west-2
    topic_arn: arn:aws:sns:us-west-2:123456789012:oxidized
```

### Cisco Spark 钩子 (ciscosparkdiff.rb)
- **功能**：将配置差异发送到 Cisco Spark 空间
- **特点**：团队协作、实时通知、差异显示
- **适用场景**：Cisco 环境、团队协作

```ruby
# 配置示例
hooks:
  cisco_spark:
    type: ciscosparkdiff
    events: [post_store]
    accesskey: your_spark_token
    space: your_space_id
    diff: true
    message: "Device %{node} configuration updated"
```

### 执行命令钩子 (exec.rb)
- **功能**：执行外部命令或脚本
- **特点**：灵活性高、可自定义、支持异步
- **适用场景**：自定义处理、系统集成

```ruby
# 配置示例
hooks:
  custom_script:
    type: exec
    events: [node_success, node_fail]
    cmd: /usr/local/bin/notify.sh
    timeout: 30
    async: true
```

### GitHub 仓库钩子 (githubrepo.rb)
- **功能**：将本地 Git 仓库推送到 GitHub
- **特点**：版本控制、协作开发、备份
- **适用场景**：开发环境、协作项目

```ruby
# 配置示例
hooks:
  github_backup:
    type: githubrepo
    events: [post_store]
    remote_repo:
      core: https://github.com/user/core-configs.git
      access: https://github.com/user/access-configs.git
    username: git_user
    password: git_password
```

### Slack 钩子 (slackdiff.rb)
- **功能**：将配置差异发送到 Slack 频道
- **特点**：团队通知、差异显示、文件上传
- **适用场景**：团队协作、实时通知

```ruby
# 配置示例
hooks:
  slack_notify:
    type: slackdiff
    events: [post_store]
    token: xoxb-your-slack-token
    channel: #network-changes
    diff: true
    message: "Device %{node} configuration updated"
```

### XMPP 钩子 (xmppdiff.rb)
- **功能**：通过 XMPP 发送配置差异到聊天室
- **特点**：实时通信、多用户聊天、差异显示
- **适用场景**：内部通信、实时通知

```ruby
# 配置示例
hooks:
  xmpp_notify:
    type: xmppdiff
    events: [post_store]
    jid: oxidized@example.com
    password: xmpp_password
    channel: network-changes@conference.example.com
    nick: oxidized-bot
```

### 空操作钩子 (noophook.rb)
- **功能**：不执行任何操作，仅用于测试
- **特点**：测试用途、调试、占位符
- **适用场景**：测试环境、调试

```ruby
# 配置示例
hooks:
  test_hook:
    type: noophook
    events: [node_success, node_fail]
```

## 钩子配置

### 基本配置
```ruby
# 全局钩子配置
hooks:
  hook_name:
    type: hook_type
    events: [event1, event2]
    # 钩子特定配置
```

### 多钩子支持
```ruby
# 支持多个钩子
hooks:
  slack:
    type: slackdiff
    events: [post_store]
    # Slack 配置
  
  github:
    type: githubrepo
    events: [post_store]
    # GitHub 配置
```

### 事件过滤
```ruby
# 特定事件钩子
hooks:
  success_only:
    type: exec
    events: [node_success]
    cmd: /bin/success-notify.sh
  
  failure_only:
    type: exec
    events: [node_fail]
    cmd: /bin/failure-alert.sh
```

## 高级功能

### 条件执行
```ruby
# 基于节点属性的条件执行
def run_hook(ctx)
  return unless ctx.node.group == 'production'
  # 仅在生产环境执行
end
```

### 错误处理
```ruby
# 钩子错误处理
def run_hook(ctx)
  begin
    # 钩子逻辑
  rescue StandardError => e
    logger.error "Hook failed: #{e.message}"
  end
end
```

### 异步执行
```ruby
# 异步钩子执行
hooks:
  async_hook:
    type: exec
    events: [post_store]
    cmd: /bin/long-running-script.sh
    async: true
    timeout: 300
```

## 扩展钩子模块

### 创建自定义钩子
1. 继承 `Oxidized::Hook` 基类
2. 实现 `validate_cfg!` 方法验证配置
3. 实现 `run_hook` 方法执行逻辑
4. 处理错误和异常情况

### 最佳实践
- 实现适当的错误处理
- 支持配置验证
- 提供详细的日志信息
- 考虑性能和资源使用
