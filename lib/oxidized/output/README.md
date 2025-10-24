# 输出模块

这个目录包含了 Oxidized 的各种输出方法，用于保存和管理网络设备配置。

## 模块说明

### 核心文件
- `output.rb` - 输出模块基类，定义所有输出方法的接口
- `file.rb` - 文件输出模块，将配置保存到本地文件系统
- `git.rb` - Git输出模块，使用Git进行版本控制
- `gitcrypt.rb` - Git加密输出模块，使用git-crypt进行加密
- `http.rb` - HTTP输出模块，通过HTTP API发送配置

## 输出模块架构

### 基类设计
所有输出模块都继承自 `Oxidized::Output::Output` 基类，必须实现以下方法：

```ruby
class MyOutput < Output
  def store(node, outputs, opt = {})
    # 存储配置
  end
  
  def fetch(node, group)
    # 获取配置
  end
  
  def version(node, group)
    # 获取版本信息
  end
end
```

### 核心功能
- **配置存储** - `store` 方法保存设备配置
- **配置获取** - `fetch` 方法检索已保存的配置
- **版本管理** - `version` 方法获取配置版本历史
- **差异比较** - `get_diff` 方法比较配置差异

### 清理功能
- **过时节点清理** - `clean_obsolete_nodes` 方法清理不再活跃的节点配置
- **自动清理** - 支持配置驱动的自动清理功能

## 输出模块详解

### 文件输出 (file.rb)
- **功能**：将配置保存到本地文件系统
- **特点**：简单、快速、无依赖
- **适用场景**：单机部署、简单备份需求

```ruby
# 配置示例
output:
  default: file
  file:
    directory: /var/lib/oxidized/configs
```

### Git输出 (git.rb)
- **功能**：使用Git进行版本控制
- **特点**：完整的版本历史、差异比较、分支管理
- **适用场景**：需要版本控制的场景

```ruby
# 配置示例
output:
  default: git
  git:
    user: Oxidized
    email: oxidized@example.com
    repo: /var/lib/oxidized/git-repo
```

### Git加密输出 (gitcrypt.rb)
- **功能**：使用git-crypt加密Git仓库
- **特点**：配置加密存储、访问控制
- **适用场景**：敏感配置的安全存储

```ruby
# 配置示例
output:
  default: gitcrypt
  gitcrypt:
    user: Oxidized
    email: oxidized@example.com
    repo: /var/lib/oxidized/encrypted-repo
    users:
      - user1@example.com
      - user2@example.com
```

### HTTP输出 (http.rb)
- **功能**：通过HTTP API发送配置到远程服务器
- **特点**：远程存储、API集成
- **适用场景**：集中化配置管理、第三方系统集成

```ruby
# 配置示例
output:
  default: http
  http:
    user: api_user
    password: api_password
    url: https://config-server.example.com/api/backup
```

## 配置管理

### 输出选择
```ruby
# 全局默认输出
output:
  default: git

# 节点特定输出
nodes:
  - name: router1
    output: file
```

### 多输出支持
```ruby
# 支持多个输出方法
output:
  default: git
  file:
    directory: /backup/configs
  git:
    repo: /var/lib/oxidized/git
```

## 扩展输出模块

### 创建自定义输出模块
1. 继承 `Oxidized::Output::Output` 基类
2. 实现必需的接口方法
3. 处理存储和检索逻辑
4. 支持配置选项

### 最佳实践
- 实现原子性操作
- 提供适当的错误处理
- 支持配置验证
- 实现清理功能
