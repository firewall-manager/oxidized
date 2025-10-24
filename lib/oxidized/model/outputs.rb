# Oxidized 模型输出管理模块
# 用于管理设备配置输出的收集和组织
module Oxidized
  class Model
    using Refinements

    # 输出集合类
    # 管理多个配置输出的收集、组织和格式化
    class Outputs
      # 转换为配置字符串
      # @return [String] 所有输出的配置字符串
      def to_cfg
        type_to_str(nil)
      end

      # 根据类型转换为字符串
      # @param want_type [String, nil] 想要的输出类型
      # @return [String] 指定类型的输出字符串
      def type_to_str(want_type)
        type(want_type).map { |out| out }.join
      end

      # 添加输出到集合末尾
      # @param output [String] 要添加的输出
      def <<(output)
        @outputs << output
      end

      # 添加输出到集合开头
      # @param output [String] 要添加的输出
      def unshift(output)
        @outputs.unshift output
      end

      # 获取所有输出
      # @return [Array] 所有输出的数组
      def all
        @outputs
      end

      # 根据类型筛选输出
      # @param type [String] 输出类型
      # @return [Array] 指定类型的输出数组
      def type(type)
        @outputs.select { |out| out.type == type }
      end

      # 获取所有输出类型
      # @return [Array] 所有输出类型的数组
      def types
        @outputs.map { |out| out.type }.uniq.compact
      end

      private

      # 初始化输出集合
      def initialize
        @outputs = []
      end
    end
  end
end
