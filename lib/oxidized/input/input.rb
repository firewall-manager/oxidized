module Oxidized
  # 提示符检测失败异常类
  # 当无法检测到预期的命令提示符时抛出此异常
  class PromptUndetect < OxidizedError; end

  # 输入模块基类
  # 所有输入模块（SSH、Telnet、HTTP等）的父类
  # 定义了通用的错误处理机制和日志记录功能
  class Input
    include SemanticLogger::Loggable  # 包含语义日志记录功能
    include Oxidized::Config::Vars    # 包含配置变量访问功能

    # 错误处理配置
    # 定义了不同级别日志应该处理的异常类型
    RESCUE_FAIL = {
      debug: [
        Errno::ECONNREFUSED  # 连接被拒绝错误（调试级别）
      ],
      warn:  [
        IOError,              # IO错误
        PromptUndetect,       # 提示符检测失败
        Timeout::Error,       # 超时错误
        Errno::ECONNRESET,    # 连接重置错误
        Errno::EHOSTUNREACH,  # 主机不可达错误
        Errno::ENETUNREACH,   # 网络不可达错误
        Errno::EPIPE,         # 管道错误
        Errno::ETIMEDOUT      # 连接超时错误
      ]
    }.freeze
  end
end
