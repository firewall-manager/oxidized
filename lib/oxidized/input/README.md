# 输入模块

这个目录包含了 Oxidized 的各种输入方法，用于连接和获取网络设备的配置。

## 模块说明

### 核心文件
- `input.rb` - 输入模块基类，定义所有输入方法的接口
- `cli.rb` - 命令行输入模块
- `exec.rb` - 执行命令输入模块

### 网络协议输入
- `ssh.rb` - SSH连接输入模块
- `telnet.rb` - Telnet连接输入模块
- `http.rb` - HTTP/HTTPS连接输入模块

### 文件传输输入
- `ftp.rb` - FTP文件传输输入模块
- `scp.rb` - SCP文件传输输入模块
- `tftp.rb` - TFTP文件传输输入模块

## 输入模块架构

### 基类设计
所有输入模块都继承自 `Oxidized::Input::Input` 基类，必须实现以下方法：

```ruby
class MyInput < Input
  def connect(node)
    # 建立连接
  end
  
  def get
    # 获取配置
  end
  
  def disconnect
    # 断开连接
  end
end
```

### 连接管理
- **连接建立** - `connect(node)` 方法建立到设备的连接
- **配置获取** - `get` 方法获取设备配置
- **连接断开** - `disconnect` 方法清理连接资源

### 错误处理
输入模块需要处理各种网络错误：
- 连接超时
- 认证失败
- 网络不可达
- 协议错误

### 配置支持
每个输入模块支持特定的配置选项：
- 连接参数（主机、端口、超时）
- 认证信息（用户名、密码、密钥）
- 协议特定选项

## 使用示例

### SSH输入
```ruby
# 配置SSH连接
node.input = 'ssh'
node.username = 'admin'
node.password = 'password'
```

### Telnet输入
```ruby
# 配置Telnet连接
node.input = 'telnet'
node.username = 'admin'
node.password = 'password'
```

### 多输入支持
```ruby
# 支持多个输入方法，按优先级尝试
node.input = 'ssh,telnet'
```

## 扩展输入模块

### 创建自定义输入模块
1. 继承 `Oxidized::Input::Input` 基类
2. 实现必需的接口方法
3. 处理连接和错误情况
4. 支持配置选项

### 最佳实践
- 实现适当的超时处理
- 提供详细的错误信息
- 支持多种认证方式
- 处理网络中断和重连
