module Oxidized
  class Config
    # 配置变量模块
    # 提供访问节点、组或全局级别用户变量的便捷方法
    module Vars
      # 获取变量的便捷方法
      # 按照优先级顺序查找变量：节点级别 > 组模型级别 > 组级别 > 模型级别 > 全局级别
      # @param name [String, Symbol] 变量名称
      # @return [Object, nil] 变量值，如果未找到则返回nil
      def vars(name)
        model_name = @node.model.class.name.to_s.downcase
        groups = Oxidized.config.groups
        models = Oxidized.config.models
        group = groups[@node.group] if groups.has_key?(@node.group)
        model = models[model_name] if models.has_key?(model_name)
        group_model = group.models[model_name] if group&.models&.has_key?(model_name)

        # 定义变量查找的作用域，按优先级排序
        scopes = {
          node:        @node.vars,        # 节点级别变量（最高优先级）
          group_model: group_model&.vars, # 组模型级别变量
          group:       group&.vars,       # 组级别变量
          model:       model&.vars,       # 模型级别变量
          vars:        Oxidized.config.vars # 全局变量（最低优先级）
        }

        # 按优先级顺序查找变量
        scopes.each do |scope_name, scope|
          next unless scope&.has_key?(name.to_s)

          val = scope[name.to_s]
          if val.nil?
            Oxidized.logger.debug "vars.rb: scope #{scope_name} has key #{name} with value nil, ignoring scope"
          else
            Oxidized.logger.debug "vars.rb: scope #{scope_name} has key #{name} with value #{val}, using scope"
            return val
          end
        end
        nil
      end
    end
  end
end
