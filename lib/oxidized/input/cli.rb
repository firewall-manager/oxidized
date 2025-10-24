module Oxidized
  class Input
    # CLI（命令行界面）通用模块
    # 为所有基于命令行的输入模块（SSH、Telnet等）提供通用功能
    # 包括登录处理、命令执行、连接管理等
    module CLI
      attr_reader :node  # 当前连接的节点对象

      # 初始化CLI模块
      # 设置登录后命令列表、登出前命令列表和认证信息
      def initialize
        @post_login = []   # 登录后要执行的命令列表
        @pre_logout = []   # 登出前要执行的命令列表
        @username, @password, @exec = nil  # 用户名、密码和执行模式标志
      end

      # 获取设备配置的主方法
      # 连接设备 -> 执行模型定义的获取命令 -> 断开连接
      def get
        connect_cli
        d = node.model.get
        disconnect
        d
      rescue PromptUndetect
        disconnect
        raise
      end

      # 执行登录后的命令
      # 在成功登录后执行预定义的后登录命令
      def connect_cli
        logger.debug "Running post_login commands at #{node.name}"
        @post_login.each do |command, block|
          logger.debug "Running post_login command: #{command.inspect}, " \
                       "block: #{block.inspect} at #{node.name}"
          block ? block.call : (cmd command)
        end
      end

      # 执行登出前的命令
      # 在断开连接前执行预定义的登出前命令
      def disconnect_cli
        logger.debug "Running pre_logout commands at #{node.name}"
        @pre_logout.each { |command, block| block ? block.call : (cmd command, nil) }
      end

      # 添加登录后要执行的命令
      # @param cmd [String] 要执行的命令字符串
      # @param block [Proc] 要执行的代码块
      def post_login(cmd = nil, &block)
        return if @exec  # 如果使用exec模式则跳过

        @post_login << [cmd, block]
      end

      # 添加登出前要执行的命令
      # @param cmd [String] 要执行的命令字符串
      # @param block [Proc] 要执行的代码块
      def pre_logout(cmd = nil, &block)
        return if @exec  # 如果使用exec模式则跳过

        @pre_logout << [cmd, block]
      end

      # 设置用户名提示符的正则表达式
      # @param regex [Regexp] 匹配用户名提示符的正则表达式
      # @return [Regexp] 用户名提示符正则表达式
      def username(regex = /^(Username|login)/)
        @username || (@username = regex)
      end

      # 设置密码提示符的正则表达式
      # @param regex [Regexp] 匹配密码提示符的正则表达式
      # @return [Regexp] 密码提示符正则表达式
      def password(regex = /^Password/)
        @password || (@password = regex)
      end

      # 设置换行符
      # @param newline_str [String] 换行符字符串
      # @return [String] 换行符
      def newline(newline_str = "\n")
        @newline || (@newline = newline_str)
      end

      # 执行登录过程
      # 根据提示符匹配用户名和密码输入，完成认证过程
      def login
        match_re = [@node.prompt]  # 基础提示符匹配列表
        match_re << @username if @username  # 添加用户名提示符
        match_re << @password if @password  # 添加密码提示符
        
        # 循环等待匹配，直到收到设备提示符
        until (match = expect(match_re)) == @node.prompt
          cmd(@node.auth[:username], nil) if match == @username  # 发送用户名
          cmd(@node.auth[:password], nil) if match == @password  # 发送密码
          match_re.delete match  # 移除已匹配的提示符
        end
      end
    end
  end
end
