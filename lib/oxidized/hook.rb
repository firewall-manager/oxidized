module Oxidized
  # 钩子管理器类
  # 负责注册、管理和触发各种事件钩子
  class HookManager
    include SemanticLogger::Loggable

    class << self
      # 从配置创建钩子管理器
      # @param cfg [Hash] 配置哈希
      # @return [HookManager] 钩子管理器实例
      def from_config(cfg)
        mgr = new
        cfg.hooks.each do |name, h_cfg|
          h_cfg.events.each do |event|
            mgr.register event.to_sym, name, h_cfg.type, h_cfg
          end
        end
        mgr
      end
    end

    # 钩子上下文结构体
    # 传递给每个钩子的上下文，可以包含与事件相关的任何信息
    # 至少包含事件名称
    # 参数keyword_init: true是ruby < 3.2所需的，在支持ruby 3.1后可以删除
    HookContext = Struct.new(:event, :node, :job, :commitref, keyword_init: true)

    # 已注册钩子结构体
    # 钩子实例的容器
    RegisteredHook = Struct.new(:name, :hook)

    # 支持的事件类型
    EVENTS = %i[
      node_success
      node_fail
      post_store
      nodes_done
    ].freeze
    # 已注册的钩子哈希表
    attr_reader :registered_hooks

    # 初始化钩子管理器
    def initialize
      @registered_hooks = Hash.new { |h, k| h[k] = [] }
    end

    # 注册钩子
    # @param event [Symbol] 事件类型
    # @param name [String] 钩子名称
    # @param hook_type [String] 钩子类型
    # @param cfg [Hash] 钩子配置
    def register(event, name, hook_type, cfg)
      unless EVENTS.include? event
        raise ArgumentError,
              "unknown event #{event}, available: #{EVENTS.join ','}"
      end

      Oxidized.mgr.add_hook(hook_type) || raise("cannot load hook '#{hook_type}', not found")
      begin
        hook = Oxidized.mgr.hook.fetch(hook_type).new
      rescue KeyError
        raise KeyError, "cannot find hook #{hook_type.inspect}"
      end

      hook.cfg = cfg

      @registered_hooks[event] << RegisteredHook.new(name, hook)
      logger.debug "Hook #{name.inspect} registered #{hook.class} for event #{event.inspect}"
    end

    # 处理事件
    # 触发指定事件的所有注册钩子
    # @param event [Symbol] 事件类型
    # @param ctx_params [Hash] 上下文参数
    def handle(event, ctx_params = {})
      ctx = HookContext.new ctx_params
      ctx.event = event

      @registered_hooks[event].each do |r_hook|
        r_hook.hook.run_hook ctx
      rescue StandardError => e
        logger.error "Hook #{r_hook.name} (#{r_hook.hook}) failed " \
                     "(#{e.inspect}) for event #{event.inspect}"
      end
    end
  end

  # 钩子抽象基类
  # 所有钩子类的基类，提供基本的钩子功能
  class Hook
    include SemanticLogger::Loggable

    # 钩子配置
    attr_reader :cfg

    # 设置钩子配置
    # @param cfg [Hash] 配置哈希
    def cfg=(cfg)
      @cfg = cfg
      validate_cfg! if respond_to? :validate_cfg!
    end

    # 运行钩子
    # 子类必须实现此方法
    # @param _ctx [HookContext] 钩子上下文
    def run_hook(_ctx)
      raise NotImplementedError
    end
  end
end
