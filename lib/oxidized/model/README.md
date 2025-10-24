# 设备模型模块

这个目录包含了 Oxidized 的各种网络设备模型，用于解析和标准化不同厂商设备的配置。

## 模块说明

### 核心文件
- `model.rb` - 设备模型基类，定义所有设备模型的接口
- `outputs.rb` - 输出处理模块

### 主要厂商模型

#### 思科 (Cisco)
- `ios.rb` - Cisco IOS 设备模型
- `iosxe.rb` - Cisco IOS XE 设备模型
- `iosxr.rb` - Cisco IOS XR 设备模型
- `nxos.rb` - Cisco NX-OS 设备模型
- `catos.rb` - Cisco Catalyst OS 设备模型
- `asa.rb` - Cisco ASA 防火墙模型
- `ciscovpn3k.rb` - Cisco VPN 3000 模型

#### 瞻博 (Juniper)
- `junos.rb` - Juniper Junos 设备模型
- `screenos.rb` - Juniper ScreenOS 模型

#### 华为 (Huawei)
- `vrp.rb` - Huawei VRP 设备模型
- `h3c.rb` - H3C 设备模型

#### 惠普 (HP/HPE)
- `procurve.rb` - HP ProCurve 交换机模型
- `comware.rb` - HPE Comware 设备模型

#### 其他厂商
- `eos.rb` - Arista EOS 设备模型
- `ftos.rb` - Force10/FTOS 设备模型
- `ironware.rb` - Foundry IronWare 设备模型
- `cumulus.rb` - Cumulus Linux 模型

## 设备模型架构

### 基类设计
所有设备模型都继承自 `Oxidized::Model` 基类，包含以下核心组件：

```ruby
class MyModel < Model
  # 设备提示符配置
  prompt /^[\w.@-]+[#>]\s?$/
  
  # 命令配置
  cmd 'show version' do |cfg|
    # 处理命令输出
  end
  
  # 配置获取
  cmd 'show running-config' do |cfg|
    cfg
  end
end
```

### 核心组件

#### 提示符处理
- **登录提示符** - 识别设备登录状态
- **特权模式提示符** - 识别特权模式状态
- **配置模式提示符** - 识别配置模式状态

#### 命令执行
- **配置获取命令** - 获取设备配置的命令
- **状态检查命令** - 检查设备状态的命令
- **命令过滤** - 过滤敏感信息

#### 输出处理
- **配置标准化** - 统一不同设备的配置格式
- **敏感信息过滤** - 移除密码等敏感信息
- **配置验证** - 验证配置的完整性

## 模型开发指南

### 基本结构
```ruby
class NewModel < Model
  # 1. 定义提示符
  prompt /^[\w.@-]+[#>]\s?$/
  
  # 2. 配置登录
  expect /Password:/ do |data, re|
    send @node.auth[:password] + "\n"
    data
  end
  
  # 3. 定义命令
  cmd 'show version' do |cfg|
    comment cfg
  end
  
  # 4. 获取配置
  cmd 'show running-config' do |cfg|
    cfg.gsub! /^Current configuration : [^\n]*\n/, ''
    cfg.gsub! /^! [^\n]*\n/, ''
    cfg
  end
end
```

### 提示符配置
```ruby
# 基本提示符
prompt /^[\w.@-]+[#>]\s?$/

# 多行提示符
prompt /^[\w.@-]+[#>]\s?$/

# 特权模式提示符
prompt /^[\w.@-]+#\s?$/
```

### 认证处理
```ruby
# 密码认证
expect /Password:/ do |data, re|
  send @node.auth[:password] + "\n"
  data
end

# 用户名认证
expect /Username:/ do |data, re|
  send @node.auth[:username] + "\n"
  data
end
```

### 命令定义
```ruby
# 基本命令
cmd 'show version'

# 带参数的命令
cmd 'show running-config'

# 条件命令
cmd 'show vlan' do |cfg|
  comment cfg
end
```

### 配置处理
```ruby
# 配置清理
cmd 'show running-config' do |cfg|
  # 移除时间戳
  cfg.gsub! /^Current configuration : [^\n]*\n/, ''
  
  # 移除注释
  cfg.gsub! /^! [^\n]*\n/, ''
  
  # 移除空行
  cfg.gsub! /^\n/, ''
  
  cfg
end
```

## 高级功能

### 敏感信息过滤
```ruby
# 过滤密码
cfg.gsub! /^(enable|password|secret) \S+/, '\1 <secret hidden>'

# 过滤SNMP社区
cfg.gsub! /^(snmp-server community) \S+/, '\1 <secret hidden>'
```

### 配置验证
```ruby
# 验证配置完整性
cmd 'show running-config' do |cfg|
  raise 'Config truncated' if cfg.length < 100
  cfg
end
```

### 多设备支持
```ruby
# 支持多种设备类型
class GenericModel < Model
  # 通用配置
end

class SpecificModel < GenericModel
  # 特定设备配置
end
```

## 最佳实践

### 错误处理
- 实现适当的超时处理
- 处理连接失败情况
- 验证命令执行结果

### 性能优化
- 最小化命令数量
- 使用高效的命令
- 避免不必要的等待

### 安全性
- 过滤敏感信息
- 验证配置完整性
- 处理认证失败

### 可维护性
- 清晰的代码结构
- 详细的注释
- 适当的错误信息
