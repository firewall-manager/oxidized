# 数据源模块

这个目录包含了 Oxidized 的各种数据源模块，用于获取网络设备列表和配置信息。

## 模块说明

### 核心文件
- `source.rb` - 数据源模块基类，定义所有数据源方法的接口
- `csv.rb` - CSV文件数据源模块
- `jsonfile.rb` - JSON文件数据源模块
- `http.rb` - HTTP API数据源模块
- `sql.rb` - SQL数据库数据源模块

## 数据源模块架构

### 基类设计
所有数据源模块都继承自 `Oxidized::Source::Source` 基类，必须实现以下方法：

```ruby
class MySource < Source
  def load(node_want = nil)
    # 加载节点列表
  end
end
```

### 核心功能
- **节点加载** - `load` 方法获取设备列表
- **模型映射** - 自动映射设备型号
- **组映射** - 支持设备分组
- **变量插值** - 处理节点特定变量

### 配置解析
数据源模块支持多级配置优先级：
1. 节点级别配置
2. 组模型级别配置
3. 组级别配置
4. 模型级别配置
5. 全局级别配置

## 数据源模块详解

### CSV数据源 (csv.rb)
- **功能**：从CSV文件读取设备信息
- **特点**：简单、易编辑、支持分隔符配置
- **适用场景**：小型网络、手动管理

```ruby
# 配置示例
source:
  default: csv
  csv:
    file: /var/lib/oxidized/router.db
    delimiter: /:/
    map:
      name: 0
      model: 1
      username: 2
      password: 3
```

#### CSV文件格式
```
router1:ios:admin:password
router2:junos:admin:password
switch1:procurve:admin:password
```

### JSON文件数据源 (jsonfile.rb)
- **功能**：从JSON文件读取设备信息
- **特点**：结构化数据、支持嵌套对象
- **适用场景**：复杂配置、程序化管理

```ruby
# 配置示例
source:
  default: jsonfile
  jsonfile:
    file: /var/lib/oxidized/devices.json
    map:
      name: "hostname"
      model: "os"
      ip: "ip_address"
```

#### JSON文件格式
```json
[
  {
    "hostname": "router1",
    "os": "ios",
    "ip_address": "192.168.1.1",
    "group": "core"
  }
]
```

### HTTP数据源 (http.rb)
- **功能**：通过HTTP API获取设备信息
- **特点**：动态数据、实时更新、远程管理
- **适用场景**：大型网络、自动化管理

```ruby
# 配置示例
source:
  default: http
  http:
    url: https://cmdb.example.com/api/devices
    user: api_user
    password: api_password
    map:
      name: "hostname"
      model: "os"
```

### SQL数据源 (sql.rb)
- **功能**：从SQL数据库读取设备信息
- **特点**：结构化存储、复杂查询、事务支持
- **适用场景**：企业环境、数据库集成

```ruby
# 配置示例
source:
  default: sql
  sql:
    adapter: mysql
    host: localhost
    database: oxidized
    table: devices
    user: oxidized
    password: password
    map:
      name: "hostname"
      model: "os"
```

## 高级功能

### 模型映射
```ruby
# 全局模型映射
model_map:
  cisco: ios
  juniper: junos
  hp: procurve
```

### 组映射
```ruby
# 全局组映射
group_map:
  core: core-routers
  access: access-switches
  distribution: dist-switches
```

### 变量插值
```ruby
# 节点特定变量
vars:
  enable: enable_password
  snmp: public
  ntp: 192.168.1.1
```

### GPG加密支持
```ruby
# 支持GPG加密的数据源文件
source:
  csv:
    file: /var/lib/oxidized/encrypted.db
    gpg: true
    gpg_password: "encryption_password"
```

## 扩展数据源模块

### 创建自定义数据源
1. 继承 `Oxidized::Source::Source` 基类
2. 实现 `load` 方法
3. 处理配置解析和映射
4. 支持错误处理

### 最佳实践
- 实现适当的错误处理
- 支持配置验证
- 提供详细的日志信息
- 支持分页和过滤
