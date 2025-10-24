module Oxidized
  module Source
    # SQL源模块
    # 从SQL数据库中读取设备信息，支持多种数据库适配器和SSL连接
    class SQL < Source
      begin
        require 'sequel'
      rescue LoadError
        raise OxidizedError, 'sequel not found: sudo gem install sequel'
      end

      # 设置SQL源配置
      # 如果配置为空，则设置默认配置并提示用户编辑配置文件
      def setup
        if @cfg.empty?
          Oxidized.asetus.user.source.sql.adapter   = 'sqlite'
          Oxidized.asetus.user.source.sql.database  = File.join(Config::ROOT, 'sqlite.db')
          Oxidized.asetus.user.source.sql.table     = 'devices'
          Oxidized.asetus.user.source.sql.map.name  = 'name'
          Oxidized.asetus.user.source.sql.map.model = 'rancid'
          Oxidized.asetus.save :user
          raise NoConfig, "No source sql config, edit #{Oxidized::Config.configfile}"
        end

        # map.name是必需的
        return if @cfg.map.has_key?('name')

        raise InvalidConfig, "map/name is a mandatory source attribute, edit #{Oxidized::Config.configfile}"
      end

      # 从SQL数据库加载节点信息
      # @param node_want [String, nil] 要加载的特定节点名称
      # @return [Array] 节点信息数组
      def load(node_want = nil)
        nodes = []
        db = connect
        query = db[@cfg.table.to_sym]
        query = query.with_sql(@cfg.query) if @cfg.query?

        query = query.where(@cfg.map.name.to_sym => node_want) if node_want

        query.each do |node|
          # 映射节点参数
          keys = {}
          @cfg.map.each { |key, sql_column| keys[key.to_sym] = node_var_interpolate node[sql_column.to_sym] }
          keys[:model] = map_model keys[:model] if keys.has_key? :model
          keys[:group] = map_group keys[:group] if keys.has_key? :group

          # 映射节点特定变量
          vars = {}
          @cfg.vars_map.each do |key, sql_column|
            vars[key.to_s] = node_var_interpolate node[sql_column.to_sym]
          end
          keys[:vars] = vars unless vars.empty?

          nodes << keys
        end
        db.disconnect
        nodes
      end

      private

      # 初始化SQL源模块
      def initialize
        super
        @cfg = Oxidized.config.source.sql
      end

      # 连接到SQL数据库
      # @return [Sequel::Database] 数据库连接对象
      def connect
        options = {
          adapter:  @cfg.adapter,
          host:     @cfg.host?,
          user:     @cfg.user?,
          password: @cfg.password?,
          database: @cfg.database,
          ssl_mode: @cfg.ssl_mode?
        }
        if @cfg.with_ssl?
          options.merge!(sslca:   @cfg.ssl_ca?,
                         sslcert: @cfg.ssl_cert?,
                         sslkey:  @cfg.ssl_key?)
        end
        Sequel.connect(options)
      rescue Sequel::AdapterNotFound => e
        raise OxidizedError, "SQL adapter gem not installed: " + e.message
      end
    end
  end
end
