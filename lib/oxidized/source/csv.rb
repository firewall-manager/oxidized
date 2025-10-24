module Oxidized
  module Source
    # CSV源模块
    # 从CSV格式的文件中读取设备信息，支持分隔符配置和字段映射
    class CSV < Source
      # 初始化CSV源模块
      def initialize
        @cfg = Oxidized.config.source.csv
        super
      end

      # 设置CSV源配置
      # 如果配置为空，则设置默认配置并提示用户编辑配置文件
      def setup
        if @cfg.empty?
          Oxidized.asetus.user.source.csv.file      = File.join(Config::ROOT, 'router.db')
          Oxidized.asetus.user.source.csv.delimiter = /:/
          Oxidized.asetus.user.source.csv.map.name  = 0
          Oxidized.asetus.user.source.csv.map.model = 1
          Oxidized.asetus.user.source.csv.gpg       = false
          Oxidized.asetus.save :user
          raise NoConfig, "no source csv config, edit #{Oxidized::Config.configfile}"
        end
        require 'gpgme' if @cfg.gpg?

        # map.name是必需的
        return if @cfg.map.has_key?('name')

        raise InvalidConfig, "map/name is a mandatory source attribute, edit #{Oxidized::Config.configfile}"
      end

      # 从CSV文件加载节点信息
      # @param _node_want [String, nil] 要加载的特定节点名称（未使用）
      # @return [Array] 节点信息数组
      def load(_node_want = nil)
        nodes = []
        open_file.each_line do |line|
          next if line =~ /^\s*#/  # 跳过注释行

          data = line.chomp.split(@cfg.delimiter, -1)
          next if data.empty?  # 跳过空行

          # 映射节点参数
          keys = {}
          @cfg.map.each do |key, position|
            keys[key.to_sym] = node_var_interpolate data[position]
          end
          keys[:model] = map_model keys[:model] if keys.has_key? :model
          keys[:group] = map_group keys[:group] if keys.has_key? :group

          # 映射节点特定变量
          vars = {}
          @cfg.vars_map.each do |key, position|
            vars[key.to_s] = node_var_interpolate data[position]
          end
          keys[:vars] = vars unless vars.empty?

          nodes << keys
        end
        nodes
      end
    end
  end
end
