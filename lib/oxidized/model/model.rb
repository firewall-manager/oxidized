require 'strscan'
require_relative 'outputs'

# Oxidized 模型基类
# 所有设备模型的基础类，提供命令执行、配置处理、输出管理等核心功能
module Oxidized
  class Model
    include SemanticLogger::Loggable

    using Refinements

    include Oxidized::Config::Vars

    class << self
      # 类继承时的初始化处理
      # 为新的模型类设置必要的实例变量和数据结构
      # @param klass [Class] 继承的类
      def inherited(klass)
        super
        if klass.superclass == Oxidized::Model
          # 初始化新模型的实例变量
          klass.instance_variable_set('@cmd',     Hash.new { |h, k| h[k] = [] })  # 命令哈希表
          klass.instance_variable_set('@cfg',     Hash.new { |h, k| h[k] = [] })  # 配置哈希表
          klass.instance_variable_set('@procs',   Hash.new { |h, k| h[k] = [] }) # 处理过程哈希表
          klass.instance_variable_set '@expect',  []                              # 期望模式数组
          klass.instance_variable_set '@comment', nil                             # 注释字符
          klass.instance_variable_set '@prompt',  nil                             # 提示符模式
        else # 继承现有模型时，复制其变量
          instance_variables.each do |var|
            iv = instance_variable_get(var)
            klass.instance_variable_set var, iv.dup
            @cmd[:cmd] = iv[:cmd].dup if var.to_s == "@cmd"
          end
        end
      end

      # 设置注释字符
      # @param str [String] 注释字符，默认为 "# "
      # @return [String] 设置的注释字符
      def comment(str = "# ")
        @comment = if block_given?
                     yield
                   elsif not @comment
                     str
                   else
                     @comment
                   end
      end

      # 设置提示符正则表达式
      # @param regex [Regexp] 提示符匹配的正则表达式
      # @return [Regexp] 设置的提示符正则表达式
      def prompt(regex = nil)
        @prompt = regex || @prompt
      end

      # 配置处理方法
      # @param methods [Array] 配置方法数组
      # @param args [Hash] 参数哈希
      # @param block [Proc] 处理块
      def cfg(*methods, **args, &block)
        [methods].flatten.each do |method|
          process_args_block(@cfg[method.to_s], args, block)
        end
      end

      # 获取所有配置
      # @return [Hash] 配置哈希表
      def cfgs
        @cfg
      end

      # 添加命令
      # @param cmd_arg [String, Symbol] 命令参数
      # @param args [Hash] 参数哈希
      # @param block [Proc] 处理块
      def cmd(cmd_arg = nil, **args, &block)
        if cmd_arg.instance_of?(Symbol)
          process_args_block(@cmd[cmd_arg], args, block)
        else
          process_args_block(@cmd[:cmd], args, [cmd_arg, block])
        end
        logger.debug "Added #{cmd_arg} to the commands list"
      end

      # 获取所有命令
      # @return [Hash] 命令哈希表
      def cmds
        @cmd
      end

      # 添加期望模式
      # @param regex [Regexp] 期望匹配的正则表达式
      # @param args [Hash] 参数哈希
      # @param block [Proc] 处理块
      def expect(regex, **args, &block)
        process_args_block(@expect, args, [regex, block])
      end

      # 清理输出数据
      # @param what [Symbol] 清理类型
      def clean(what)
        case what
        when :escape_codes
          # ANSI 转义序列正则表达式
          ansi_escape_regex = /
            \r?        # 开头的可选回车符
            \e         # ESC 字符 - 转义序列的开始
            (?:        # 不同序列类型的非捕获组:
              # 类型 1: CSI (控制序列引入符)
              \[       # 字面量 '[' - CSI 序列的开始
              [0-?]*   # 参数字节: 数字 (0-9)、分号、冒号等
              [ -\/]*  # 中间字节: 空格到斜杠字符
              [@-~]    # 最终字节: 确定实际命令
            |          # 或者
              # 类型 2: 简单转义
              [=>]     # ESC 后的单字符命令
            )
            \r?        # 结尾的可选回车符
          /x
          expect ansi_escape_regex do |data, re|
            data.gsub re, ''
          end
        end
      end

      # 获取所有期望模式
      # @return [Array] 期望模式数组
      def expects
        @expect
      end

      # 在模型开始时调用块，将块的输出添加到输出字符串的前面
      # @param args [Hash] 参数哈希
      # @param block [Proc] 处理块，应返回 [String]
      # @return [void]
      def pre(**args, &block)
        process_args_block(@procs[:pre], args, block)
      end

      # 在模型结束时调用块，将块的输出添加到输出字符串
      # @param args [Hash] 参数哈希
      # @param block [Proc] 处理块，应返回 [String]
      # @return [void]
      def post(**args, &block)
        process_args_block(@procs[:post], args, block)
      end

      # 获取处理过程哈希
      # @return [Hash] 包含 :pre 和 :post 的处理过程哈希
      attr_reader :procs

      private

      # 处理参数和块
      # @param target [Array] 目标数组
      # @param args [Hash] 参数哈希
      # @param block [Proc] 处理块
      def process_args_block(target, args, block)
        if args[:clear]
          if block.instance_of?(Array)
            target.reject! { |k, _| k == block[0] }
            target.push(block)
          else
            target.replace([block])
          end
        else
          method = args[:prepend] ? :unshift : :push
          target.send(method, block)
        end
      end
    end

    # 输入对象和节点对象
    attr_accessor :input, :node

    # 执行命令
    # @param string [String] 要执行的命令
    # @param block [Proc] 可选的命令处理块
    # @return [String, false] 命令输出或 false（如果失败）
    def cmd(string, &block)
      logger.debug "Executing #{string}"
      out = @input.cmd(string)
      return false unless out

      out = out.b unless Oxidized.config.input.utf8_encoded?
      self.class.cmds[:all].each do |all_block|
        out = instance_exec out, string, &all_block
      end
      if vars :remove_secret
        self.class.cmds[:secret].each do |all_block|
          out = instance_exec out, string, &all_block
        end
      end
      out = instance_exec out, &block if block
      process_cmd_output out, string
    end

    # 获取输出
    # @return [String] 输入对象的输出
    def output
      @input.output
    end

    # 发送数据
    # @param data [String] 要发送的数据
    def send(data)
      @input.send data
    end

    # 添加期望模式
    # @param args [Array] 参数数组
    def expect(...)
      self.class.expect(...)
    end

    # 获取配置
    # @return [Hash] 配置哈希表
    def cfg
      self.class.cfgs
    end

    # 获取提示符
    # @return [Regexp] 提示符正则表达式
    def prompt
      self.class.prompt
    end

    # 处理期望模式
    # @param data [String] 要处理的数据
    # @return [String] 处理后的数据
    def expects(data)
      self.class.expects.each do |re, cb|
        if data.match re
          data = cb.arity == 2 ? instance_exec([data, re], &cb) : instance_exec(data, &cb)
        end
      end
      data
    end

    # 获取所有命令的输出
    # @return [Outputs, false] 输出对象或 false（如果失败）
    def get
      logger.debug 'Collecting commands\' outputs'
      outputs = Outputs.new
      procs = self.class.procs
      self.class.cmds[:cmd].each do |command, block|
        out = cmd command, &block
        return false unless out

        outputs << out
      end
      procs[:pre].each do |pre_proc|
        outputs.unshift process_cmd_output(instance_eval(&pre_proc), '')
      end
      procs[:post].each do |post_proc|
        outputs << process_cmd_output(instance_eval(&post_proc), '')
      end
      outputs
    end

    # 为字符串添加注释
    # @param str [String] 要注释的字符串
    # @return [String] 添加注释后的字符串
    def comment(str)
      data = String.new('')
      str.each_line do |line|
        data << self.class.comment << line
      end
      data
    end

    # 为字符串添加 XML 注释
    # XML 注释以 <!-- 开始，以 --> 结束
    # 因为注释的第一个或最后一个字符不能是 -，即 <!--- 或 ---> 是非法的
    # 为了提高可读性，我们在注释标记的开始和结束前后添加额外的空格
    # 另外，XML 注释不能包含 --。所以我们在任何双连字符之间放置一个空格
    # 通过将任何后面跟另一个 - 的 - 替换为 '- ' 来实现
    # @param str [String] 要注释的字符串
    # @return [String] 添加 XML 注释后的字符串
    def xmlcomment(str)
      data = String.new('')
      str.each_line do |_line|
        data << '<!-- ' << str.gsub(/-(?=-)/, '- ').chomp << " -->\n"
      end
      data
    end

    # 检查是否需要屏幕抓取
    # @return [Boolean] 如果需要屏幕抓取则返回 true
    def screenscrape
      @input.class.to_s.match(/Telnet/) || vars(:ssh_no_exec)
    end

    private

    # 处理命令输出
    # @param output [String] 输出字符串
    # @param name [String] 命令名称
    # @return [String] 处理后的输出
    def process_cmd_output(output, name)
      output = String.new('') unless output.instance_of?(String)
      output.process_cmd(name)
      output
    end
  end
end
