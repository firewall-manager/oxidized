module Oxidized
  # Oxidized类的工厂方法
  class << self
    def new(*args)
      Core.new args
    end
  end

  # Oxidized核心类
  # 负责初始化所有组件、管理工作器线程和扩展加载
  class Core
    include SemanticLogger::Loggable

    # 未找到节点异常
    class NoNodesFound < OxidizedError; end

    # 初始化Oxidized核心
    # 设置管理器、钩子、节点、工作器和扩展
    # @param _args [Array] 参数数组（未使用）
    def initialize(_args)
      Oxidized.mgr = Manager.new
      Oxidized.hooks = HookManager.from_config(Oxidized.config)
      nodes = Nodes.new
      raise NoNodesFound, 'source returns no usable nodes' if nodes.empty?

      @worker = Worker.new nodes
      @need_reload = false

      # 如果接收到SIGHUP信号，排队重新加载状态
      reload_proc = proc do
        @need_reload = true
      end
      Signals.register_signal('HUP', reload_proc)

      # 加载扩展，目前只有oxidized-web
      # 我们为oxidized-web有不同的命名空间，如果需要通用的扩展加载方式需要解决：
      # - gem: oxidized-web
      # - module: Oxidized::API
      # - path: oxidized/web
      # - entrypoint: Oxidized::API::Web.new(nodes, configuration)

      # 如果请求则初始化oxidized-web
      if Oxidized.config.has_key? 'rest'
        logger.warn(
          'configuration: "rest" is deprecated. Migrate to ' \
          '"extensions.oxidized-web" and remove "rest" from the configuration'
        )
        configuration = Oxidized.config.rest
      elsif Oxidized.config.extensions['oxidized-web'].load?
        # 这个注释阻止rubocop抱怨Style/IfUnlessModifier
        configuration = Oxidized.config.extensions['oxidized-web']
      end

      if configuration
        begin
          require 'oxidized/web'
        rescue LoadError
          raise OxidizedError,
                'oxidized-web not found: install it or disable it by ' \
                'removing "rest" and "extensions.oxidized-web" from your ' \
                'configuration'
        end
        @rest = API::Web.new nodes, configuration
        @rest.run
      end
      run
    end

    private

    # 重新加载节点列表
    def reload
      logger.info("Reloading node list")
      @worker.reload
      @need_reload = false
    end

    # 运行主循环
    # 持续工作直到程序退出
    def run
      logger.debug "Starting the worker..."
      loop do
        reload if @need_reload
        @worker.work
        sleep Config::SLEEP
      end
    end
  end
end
