module Oxidized
  require 'ipaddr'
  require 'oxidized/node'
  # 不支持异常
  class NotSupported < OxidizedError; end
  # 节点未找到异常
  class NodeNotFound < OxidizedError; end

  # 节点集合类
  # 继承自Array，管理所有网络设备节点的集合
  class Nodes < Array
    include SemanticLogger::Loggable

    # 源和任务队列
    attr_accessor :source, :jobs
    alias put unshift
    
    # 加载节点列表
    # @param node_want [String, nil] 要加载的特定节点名称
    def load(node_want = nil)
      with_lock do
        new = []
        @source = Oxidized.config.source.default
        Oxidized.mgr.add_source(@source) || raise(MethodNotFound, "cannot load node source '#{@source}', not found")
        logger.info "Loading nodes"
        nodes = Oxidized.mgr.source[@source].new.load node_want
        nodes.each do |node|
          # 我们想要加载特定节点，而不是所有节点
          next unless node_want? node_want, node

          begin
            node_obj = Node.new node
            new.push node_obj
          rescue ModelNotFound => e
            logger.error "node %s raised %s with message '%s'" % [node, e.class, e.message]
          rescue Resolv::ResolvError => e
            logger.error "node %s is not resolvable, raised %s with message '%s'" % [node, e.class, e.message]
          end
        end
        size.zero? ? replace(new) : update_nodes(new)
        Output.clean_obsolete_nodes(self) if node_want.nil?
        logger.info "Loaded #{size} nodes"
      end
    end

    # 检查是否要加载指定节点
    # @param node_want [String, nil] 要查找的节点名称或IP
    # @param node [Hash] 节点信息哈希
    # @return [Boolean] 是否匹配
    def node_want?(node_want, node)
      return true unless node_want

      # rubocop:disable Style/RedundantParentheses
      node_want_ip = (IPAddr.new(node_want) rescue false)
      name_is_ip   = (IPAddr.new(node[:name]) rescue false)
      # rubocop:enable Style/RedundantParentheses
      # rubocop:todo Lint/DuplicateBranch
      if name_is_ip && (node_want_ip == node[:name])
        true
      elsif node[:ip] && (node_want_ip == node[:ip])
        true
      elsif node_want.match node[:name]
        true unless name_is_ip
      end
      # rubocop:enable Lint/DuplicateBranch
    end

    # 获取节点列表
    # @return [Array] 序列化的节点信息数组
    def list
      with_lock do
        map { |e| e.serialize }
      end
    end

    # 显示特定节点信息
    # @param node [String] 节点名称
    # @return [Hash] 节点信息哈希
    def show(node)
      with_lock do
        i = find_node_index node
        self[i].serialize
      end
    end

    # 获取组/节点名称的配置
    # #fetch由oxidized-web调用
    # @param node_name [String] 节点名称
    # @param group [String] 组名
    # @return [String] 配置内容
    def fetch(node_name, group)
      yield_node_output(node_name) do |node, output|
        output.fetch node, group
      end
    end

    # 将节点移动到队列头部
    # @param node [String] 要移动到数组头部的节点名称
    # @param opt [Hash] 选项哈希
    def next(node, opt = {})
      return if running.find_index(node)

      logger.info "Add node #{node} to running jobs"
      with_lock do
        n = del node
        n.user = opt['user']
        n.email = opt['email']
        n.msg  = opt['msg']
        n.from = opt['from']
        # 将最后任务设置为nil，以便节点被立即更新
        n.last = nil
        put n
        jobs.increment if Oxidized.config.next_adds_job?
      end
    end
    alias top next

    # 从数组头部获取节点
    # @return [Node] 节点对象
    def get
      with_lock do
        (self << shift).last
      end
    end

    # 查找节点在Nodes中的索引号
    # @param node [String] 要查找索引号的节点
    # @return [Integer] 节点在Nodes中的索引号
    def find_node_index(node)
      find_index(node) || raise(NodeNotFound, "unable to find '#{node}'")
    end

    # 返回组/节点名称的所有存储版本
    # 由oxidized-web调用
    # @param node_name [String] 节点名称
    # @param group [String] 组名
    # @return [Array] 版本信息数组
    def version(node_name, group)
      yield_node_output(node_name) do |node, output|
        output.version node, group
      end
    end

    # 获取特定版本的配置
    # @param node_name [String] 节点名称
    # @param group [String] 组名
    # @param oid [String] 对象ID
    # @return [String] 版本内容
    def get_version(node_name, group, oid)
      yield_node_output(node_name) do |node, output|
        output.get_version node, group, oid
      end
    end

    # 获取两个版本之间的差异
    # @param node_name [String] 节点名称
    # @param group [String] 组名
    # @param oid1 [String] 第一个对象ID
    # @param oid2 [String] 第二个对象ID
    # @return [Hash] 差异信息
    def get_diff(node_name, group, oid1, oid2)
      yield_node_output(node_name) do |node, output|
        output.get_diff node, group, oid1, oid2
      end
    end

    # 查找节点索引
    # @param node [String] 节点名称或IP
    # @return [Integer, nil] 节点索引或nil
    def find_index(node)
      index { |e| [e.name, e.ip].include? node }
    end

    private

    # 初始化节点集合
    # @param opts [Hash] 选项哈希
    def initialize(opts = {})
      super()
      node = opts.delete :node
      @mutex = Mutex.new # 我们与webapi线程竞争节点
      if (nodes = opts.delete(:nodes))
        replace nodes
      else
        load node
      end
    end

    # 使用锁执行操作
    # @param ... [Object] 要执行的代码块
    def with_lock(...)
      @mutex.synchronize(...)
    end

    # 从节点列表中删除节点
    # @param node [String] 要从节点列表中删除的节点
    # @return [Node] 被删除的节点
    def del(node)
      delete_at find_node_index(node)
    end

    # 获取当前正在运行的节点列表
    # @return [Nodes] 正在运行的节点列表
    def running
      Nodes.new nodes: select { |node| node.running? }
    end

    # 获取等待中的节点列表（未运行）
    # @return [Nodes] 等待中的节点列表
    def waiting
      Nodes.new nodes: select { |node| not node.running? }
    end

    # 遍历新节点列表，如果旧节点包含相同名称，则从旧节点添加最后和统计信息到新节点
    # @todo 我们可以信任名称作为唯一标识符吗？当使用组时怎么办？
    # @param nodes [Array] 用于替换+更新旧节点的节点数组
    def update_nodes(nodes)
      old = dup
      # 在self中加载Array "nodes"（Nodes类继承自Array）
      replace(nodes)
      each do |node|
        if (i = old.find_node_index(node.name))
          node.stats = old[i].stats
          node.last  = old[i].last
        end
      rescue NodeNotFound
        # 什么都不做：
        # 当找不到节点时，我们没有什么可做的：
        # 它已经被replace(nodes)加载，没有统计信息要复制
      end
      sort_by! { |x| x.last.nil? ? Time.new(0) : x.last.end }
    end

    # 为节点输出操作提供上下文
    # @param node_name [String] 节点名称
    # @yield [node, output] 节点和输出对象
    def yield_node_output(node_name)
      with_lock do
        node = find { |n| n.name == node_name }
        raise(NodeNotFound, "unable to find '#{node_name}'") if node.nil?

        output = node.output.new
        raise NotSupported unless output.respond_to? :fetch

        yield node, output
      end
    end
  end
end
