module Oxidized
  module Output
    # 清理过时节点的类方法
    # 当配置启用清理过时节点功能时，调用默认输出模块的清理方法
    def self.clean_obsolete_nodes(active_nodes)
      return unless Oxidized.config.output.clean_obsolete_nodes?

      output_name = Oxidized.config.output.default
      output = Oxidized.mgr.add_output output_name
      output[output_name].clean_obsolete_nodes(active_nodes)
    end

    # 输出模块的基类
    # 所有输出模块都继承自此类，提供通用的输出功能
    class Output
      include SemanticLogger::Loggable

      # 配置缺失异常类
      class NoConfig < OxidizedError; end

      # 将配置数据转换为字符串
      # 从配置数组中筛选出类型为'cfg'的配置项，并提取其数据内容
      def cfg_to_str(cfg)
        cfg.select { |h| h[:type] == 'cfg' }.map { |h| h[:data] }.join
      end

      # 清理过时节点的默认实现
      # 子类可以重写此方法来实现具体的清理逻辑
      def self.clean_obsolete_nodes(_active_nodes)
        logger.warn "clean_obsolete_nodes is not implemented for #{name}"
      end
    end
  end
end
