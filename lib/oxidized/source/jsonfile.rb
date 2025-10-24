module Oxidized
  module Source
    # JSON文件源模块
    # 从JSON格式的文件中读取设备信息，支持嵌套对象导航和字段映射
    class JSONFile < Source
      require "json"
      
      # 初始化JSON文件源模块
      def initialize
        @cfg = Oxidized.config.source.jsonfile
        super
      end

      # 设置JSON文件源配置
      # 如果配置为空，则设置默认配置并提示用户编辑配置文件
      def setup
        if @cfg.empty?
          Oxidized.asetus.user.source.jsonfile.file      = File.join(Oxidized::Config::ROOT,
                                                                     'router.json')
          Oxidized.asetus.user.source.jsonfile.map.name  = "name"
          Oxidized.asetus.user.source.jsonfile.map.model = "model"
          Oxidized.asetus.user.source.jsonfile.gpg       = false
          Oxidized.asetus.save :user
          raise NoConfig, "No source json config, edit #{Oxidized::Config.configfile}"
        end
        require 'gpgme' if @cfg.gpg?

        # map.name是必需的
        return if @cfg.map.has_key?('name')

        raise InvalidConfig, "map/name is a mandatory source attribute, edit #{Oxidized::Config.configfile}"
      end

      # 从JSON文件加载节点信息
      # @param * [Array] 参数（未使用）
      # @return [Array] 节点信息数组
      def load(*)
        data = JSON.parse(open_file.read)
        data = string_navigate_object(data, @cfg.hosts_location) if @cfg.hosts_location?

        transform_json(data)
      end

      private

      # 转换JSON数据为节点信息数组
      # @param data [Array] JSON数据数组
      # @return [Array] 转换后的节点信息数组
      def transform_json(data)
        nodes = []
        data.each do |node|
          next if node.empty?  # 跳过空节点

          # 映射节点参数
          keys = {}
          @cfg.map.each do |key, want_position|
            keys[key.to_sym] = node_var_interpolate string_navigate_object(node, want_position)
          end
          keys[:model] = map_model keys[:model] if keys.has_key? :model
          keys[:group] = map_group keys[:group] if keys.has_key? :group

          # 映射节点特定变量
          vars = {}
          @cfg.vars_map.each do |key, want_position|
            vars[key.to_s] = node_var_interpolate string_navigate_object(node, want_position)
          end
          keys[:vars] = vars unless vars.empty?

          nodes << keys
        end
        nodes
      end
    end
  end
end
