# 精化模块
# 为 String 类添加 Oxidized 特定的方法和属性
module Refinements
  # 使用 'refine' 关键字为 String 类定义精化
  refine String do
    # 字符串属性：类型、命令、名称
    attr_accessor :type, :cmd, :name

    # 移除字符串末尾的指定行数
    # @param lines [Integer] 要移除的行数，默认为1
    # @return [String] 移除末尾行后的字符串副本
    def cut_tail(lines = 1)
      return "" if length.zero?

      each_line.to_a[0..(-1 - lines)].join
    end

    # 移除字符串开头的指定行数
    # @param lines [Integer] 要移除的行数，默认为1
    # @return [String] 移除开头行后的字符串副本
    def cut_head(lines = 1)
      return "" if length.zero?

      each_line.to_a[lines..-1].join
    end

    # 移除字符串开头和末尾的指定行数
    # @param head [Integer] 要移除的开头行数，默认为1
    # @param tail [Integer] 要移除的末尾行数，默认为1
    # @return [String] 移除开头和末尾行后的字符串副本
    def cut_both(head = 1, tail = 1)
      return "" if length.zero?

      each_line.to_a[head..(-1 - tail)].join
    end

    # 处理命令，设置 @cmd 和 @name，除非 @name 已经设置
    # @param command [String, Proc] 要处理的命令
    def process_cmd(command)
      @cmd = command
      # rubocop:disable Naming/MemoizedInstanceVariableName
      @name ||= @cmd.to_s.strip.gsub(/\s+/, '_') # 当命令是proc时怎么办？#to_s看起来有点简陋
      # rubocop:enable Naming/MemoizedInstanceVariableName
    end

    # 从另一个 String 实例初始化 String 实例变量
    # 当给定的 str 是应用了 Oxidized 精化的 String 实例时使用
    # @param str [String] 源字符串实例
    # @raise [TypeError] 当 str 不是 String 实例时
    def init_from_string(str = '')
      raise TypeError unless str.instance_of?(String)

      @cmd  = str.instance_variable_get(:@cmd)
      @name = str.instance_variable_get(:@name)
      @type = str.instance_variable_get(:@type)
    end
  end
end
