# Oxidized 系统架构流程图

## 系统整体架构

```mermaid
graph TB
    A[Oxidized 启动] --> B[Core 初始化]
    B --> C[Manager 加载模块]
    C --> D[Source 加载节点]
    D --> E[Worker 启动]
    E --> F[Jobs 调度]
    F --> G[Node 配置获取]
    G --> H[Model 处理]
    H --> I[Output 存储]
    I --> J[Hooks 触发]
    J --> K[完成/重试]
    K --> F
    
    subgraph "核心组件"
        L[Core - 核心控制器]
        M[Manager - 模块管理器]
        N[Worker - 工作器]
        O[Jobs - 任务队列]
    end
    
    subgraph "数据源"
        P[Source - 节点源]
        Q[CSV/SQL/HTTP]
    end
    
    subgraph "设备模型"
        R[Model - 设备模型]
        S[SSH/Telnet/HTTP]
        T[命令处理]
    end
    
    subgraph "输出存储"
        U[Output - 输出模块]
        V[Git/File/HTTP]
    end
    
    subgraph "钩子系统"
        W[Hooks - 钩子]
        X[成功/失败钩子]
    end
```

## 详细工作流程

```mermaid
sequenceDiagram
    participant U as User
    participant C as Core
    participant M as Manager
    participant S as Source
    participant W as Worker
    participant J as Job
    participant N as Node
    participant MD as Model
    participant O as Output
    participant H as Hooks
    
    U->>C: 启动 Oxidized
    C->>M: 初始化管理器
    M->>S: 加载数据源
    S->>W: 提供节点列表
    W->>J: 创建任务
    J->>N: 执行节点
    N->>MD: 连接设备
    MD->>N: 获取配置
    N->>O: 存储配置
    O->>H: 触发钩子
    H->>W: 任务完成
    W->>J: 处理结果
```

## 模块关系图

```mermaid
graph LR
    subgraph "输入层"
        A[SSH Input]
        B[Telnet Input]
        C[HTTP Input]
    end
    
    subgraph "模型层"
        D[IOS Model]
        E[JunOS Model]
        F[EOS Model]
        G[其他模型...]
    end
    
    subgraph "输出层"
        H[Git Output]
        I[File Output]
        J[HTTP Output]
    end
    
    subgraph "数据源"
        K[CSV Source]
        L[SQL Source]
        M[HTTP Source]
    end
    
    A --> D
    B --> E
    C --> F
    D --> H
    E --> I
    F --> J
    K --> A
    L --> B
    M --> C
```

## 任务执行流程

```mermaid
flowchart TD
    A[开始任务] --> B{检查节点状态}
    B -->|运行中| C[跳过节点]
    B -->|空闲| D[标记为运行中]
    D --> E[创建任务线程]
    E --> F[连接设备]
    F --> G{连接成功?}
    G -->|失败| H[记录错误]
    G -->|成功| I[执行命令]
    I --> J[处理输出]
    J --> K[存储配置]
    K --> L[触发钩子]
    L --> M[更新统计]
    M --> N[标记完成]
    H --> O[重试计数]
    O --> P{重试次数}
    P -->|未超限| Q[重新排队]
    P -->|超限| R[放弃任务]
    Q --> A
    R --> S[记录失败]
    N --> T[任务结束]
    S --> T
    C --> T
```

## 配置处理流程

```mermaid
flowchart LR
    A[原始配置] --> B[Model 处理]
    B --> C[敏感信息过滤]
    C --> D[格式清理]
    D --> E[注释添加]
    E --> F[输出存储]
    F --> G[版本控制]
    G --> H[钩子触发]
    
    subgraph "Model 处理"
        I[命令执行]
        J[输出解析]
        K[格式标准化]
    end
    
    subgraph "敏感信息处理"
        L[密码隐藏]
        M[密钥移除]
        N[社区字符串过滤]
    end
    
    subgraph "输出处理"
        O[Git 提交]
        P[文件写入]
        Q[HTTP 推送]
    end
```

## 错误处理流程

```mermaid
flowchart TD
    A[任务执行] --> B{执行状态}
    B -->|成功| C[正常处理]
    B -->|超时| D[超时处理]
    B -->|连接失败| E[连接错误]
    B -->|认证失败| F[认证错误]
    B -->|其他错误| G[通用错误]
    
    C --> H[存储配置]
    D --> I[记录超时]
    E --> J[检查网络]
    F --> K[检查凭据]
    G --> L[记录错误]
    
    I --> M{重试次数}
    J --> M
    K --> M
    L --> M
    
    M -->|未超限| N[重新排队]
    M -->|超限| O[放弃任务]
    
    N --> A
    O --> P[记录最终失败]
    H --> Q[任务完成]
    P --> Q
```

## 钩子系统流程

```mermaid
flowchart TD
    A[任务完成] --> B{任务状态}
    B -->|成功| C[触发成功钩子]
    B -->|失败| D[触发失败钩子]
    
    C --> E[node_success]
    D --> F[node_fail]
    
    E --> G[post_store]
    F --> H[记录失败]
    
    G --> I[配置存储完成]
    H --> J[重试或放弃]
    
    I --> K[触发完成钩子]
    J --> L[任务结束]
    K --> M[nodes_done]
    M --> N[周期完成]
    L --> N
    N --> O[等待下一周期]
    O --> A
```

## 扩展系统架构

```mermaid
graph TB
    subgraph "核心系统"
        A[Oxidized Core]
        B[Manager]
        C[Worker]
    end
    
    subgraph "扩展模块"
        D[oxidized-web]
        E[oxidized-script]
        F[自定义模型]
        G[自定义输出]
    end
    
    subgraph "外部集成"
        H[监控系统]
        I[通知系统]
        J[版本控制]
        K[配置管理]
    end
    
    A --> D
    A --> E
    B --> F
    B --> G
    D --> H
    E --> I
    F --> J
    G --> K
```

## 性能优化流程

```mermaid
flowchart TD
    A[系统启动] --> B[加载配置]
    B --> C[初始化线程池]
    C --> D[设置并发数]
    D --> E[启动工作器]
    E --> F[任务调度]
    F --> G{队列状态}
    G -->|有空闲| H[创建新任务]
    G -->|队列满| I[等待任务完成]
    H --> J[执行任务]
    I --> K[检查完成状态]
    J --> L[任务完成]
    K --> F
    L --> M[更新统计]
    M --> N[调整性能参数]
    N --> F
```

## 安全处理流程

```mermaid
flowchart TD
    A[配置获取] --> B[敏感信息检测]
    B --> C{发现敏感信息?}
    C -->|是| D[应用过滤规则]
    C -->|否| E[直接存储]
    D --> F[隐藏密码]
    F --> G[移除密钥]
    G --> H[过滤社区字符串]
    H --> I[清理时间戳]
    I --> J[标准化输出]
    J --> E
    E --> K[安全存储]
    K --> L[访问控制]
    L --> M[审计日志]
    M --> N[配置完成]
```

这个架构流程图展示了 Oxidized 系统的完整工作原理，包括：

1. **系统初始化流程** - 从启动到运行
2. **任务执行流程** - 从节点获取到配置存储
3. **模块关系** - 各组件之间的依赖关系
4. **错误处理** - 异常情况的处理机制
5. **钩子系统** - 事件驱动的扩展机制
6. **性能优化** - 并发处理和资源管理
7. **安全处理** - 敏感信息保护机制

每个流程都经过精心设计，确保系统的可靠性、可扩展性和安全性。
