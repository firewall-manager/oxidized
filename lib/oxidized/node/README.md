# 节点模块

这个目录包含了 Oxidized 节点相关的子模块，用于管理网络设备节点的统计信息和状态跟踪。

## 模块说明

### 核心文件
- `stats.rb` - 节点统计信息模块

## 节点统计模块 (stats.rb)

### 功能说明
节点统计模块负责收集和管理网络设备节点的各种统计信息，包括：
- 配置获取次数
- 成功/失败统计
- 执行时间统计
- 最后修改时间
- 错误统计

### 核心功能

#### 统计信息收集
```ruby
# 添加任务统计
stats.add(job)

# 更新修改时间
stats.update_mtime

# 获取统计信息
stats.mtime
stats.count
stats.success_count
stats.failure_count
```

#### 时间跟踪
- **最后修改时间** - 记录配置最后修改的时间
- **执行时间** - 跟踪配置获取的执行时间
- **平均时间** - 计算平均执行时间

#### 状态统计
- **成功次数** - 记录成功的配置获取次数
- **失败次数** - 记录失败的配置获取次数
- **成功率** - 计算配置获取的成功率

### 使用示例

#### 基本统计
```ruby
# 创建统计对象
stats = Stats.new

# 添加任务统计
stats.add(job)

# 获取统计信息
puts "成功次数: #{stats.success_count}"
puts "失败次数: #{stats.failure_count}"
puts "最后修改: #{stats.mtime}"
```

#### 时间统计
```ruby
# 更新修改时间
stats.update_mtime

# 获取最后修改时间
last_modified = stats.mtime
```

#### 历史统计
```ruby
# 获取历史统计
history = stats.history

# 计算平均执行时间
avg_time = stats.average_time
```

## 统计数据结构

### 统计对象属性
- `@count` - 总任务数
- `@success_count` - 成功任务数
- `@failure_count` - 失败任务数
- `@mtime` - 最后修改时间
- `@history` - 历史记录

### 历史记录格式
```ruby
{
  start_time: Time,
  end_time: Time,
  duration: Float,
  status: Symbol,
  error_type: String,
  error_reason: String
}
```

## 统计信息用途

### 性能监控
- 跟踪配置获取性能
- 识别慢速设备
- 监控系统负载

### 故障诊断
- 记录失败原因
- 跟踪错误模式
- 识别问题设备

### 容量规划
- 分析设备数量增长
- 预测资源需求
- 优化调度策略

## 配置选项

### 历史记录大小
```ruby
# 配置历史记录大小
stats:
  history_size: 10
```

### 统计收集
```ruby
# 启用详细统计
stats:
  detailed: true
  collect_errors: true
```

## 扩展功能

### 自定义统计
```ruby
# 添加自定义统计
class CustomStats < Stats
  def add_custom_metric(name, value)
    @custom_metrics ||= {}
    @custom_metrics[name] = value
  end
end
```

### 统计导出
```ruby
# 导出统计信息
def export_stats
  {
    total: @count,
    success: @success_count,
    failure: @failure_count,
    mtime: @mtime,
    history: @history
  }
end
```

## 最佳实践

### 性能考虑
- 限制历史记录大小
- 定期清理旧数据
- 使用高效的数据结构

### 内存管理
- 避免内存泄漏
- 定期清理统计数据
- 监控内存使用

### 数据持久化
- 考虑统计数据的持久化
- 实现统计数据的备份
- 支持统计数据的恢复
