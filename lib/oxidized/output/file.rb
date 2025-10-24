module Oxidized
  module Output
    # 文件输出模块
    # 将设备配置保存到本地文件系统中
    # 注意：Ruby的File类必须使用::File访问以避免命名冲突
    class File < Output
      require 'fileutils'

      # 提交引用，用于跟踪文件路径
      attr_reader :commitref

      # 初始化文件输出模块
      def initialize
        super
        @cfg = Oxidized.config.output.file
      end

      # 设置文件输出配置
      # 如果配置为空，则设置默认配置并提示用户编辑配置文件
      def setup
        return unless @cfg.empty?

        Oxidized.asetus.user.output.file.directory = ::File.join(Config::ROOT, 'configs')
        Oxidized.asetus.save :user
        raise NoConfig, "no output file config, edit #{Oxidized::Config.configfile}"
      end

      # 存储节点配置到文件
      # @param node [String] 节点名称
      # @param outputs [Oxidized::Models::Outputs] 输出对象
      # @param opt [Hash] 节点变量哈希
      def store(node, outputs, opt = {})
        file = ::File.expand_path @cfg.directory
        file = ::File.join ::File.dirname(file), opt[:group] if opt[:group]
        FileUtils.mkdir_p file
        file = ::File.join file, node
        ::File.write(file, outputs.to_cfg)
        @commitref = file
      end

      # 获取节点配置
      # @param node [Object] 节点对象
      # @param group [String] 组名
      # @return [String, nil] 配置内容或nil
      def fetch(node, group)
        cfg_dir   = ::File.expand_path @cfg.directory
        node_name = node.name

        if group # 用户明确指定了组
          cfg_dir = ::File.join ::File.dirname(cfg_dir), group
          ::File.read ::File.join(cfg_dir, node_name)
        elsif ::File.exist? ::File.join(cfg_dir, node_name) # 节点配置文件存储在基础目录中
          ::File.read ::File.join(cfg_dir, node_name)
        else
          path = Dir.glob(::File.join(::File.dirname(cfg_dir), '**', node_name)).first # 在所有组中查找节点
          ::File.read path
        end
      rescue Errno::ENOENT
        nil
      end

      # 获取版本信息（文件输出不支持版本控制）
      # @param _node [Object] 节点对象
      # @param _group [String] 组名
      # @return [Array] 空数组
      def version(_node, _group)
        # 文件输出不支持版本控制
        []
      end

      # 获取特定版本的配置（文件输出不支持版本控制）
      # @param _node [Object] 节点对象
      # @param _group [String] 组名
      # @param _oid [String] 对象ID
      # @return [String] 不支持提示
      def get_version(_node, _group, _oid)
        'not supported'
      end

      # 获取节点文件路径
      # @param node_name [String] 节点名称
      # @param group_name [String, nil] 组名
      # @return [String] 节点文件路径
      def self.node_path(node_name, group_name = nil)
        cfg_dir = ::File.expand_path Oxidized.config.output.file.directory

        if group_name
          ::File.join ::File.dirname(cfg_dir), group_name, node_name
        else
          ::File.join cfg_dir, node_name
        end
      end

      # 清理过时的节点文件
      # 删除不再活跃的节点配置文件
      # @param active_nodes [Array] 活跃节点列表
      def self.clean_obsolete_nodes(active_nodes)
        cfg_dir = ::File.expand_path Oxidized.config.output.file.directory
        dir_base = ::File.dirname(cfg_dir)
        default_dir = ::File.basename(cfg_dir)

        keep_files = active_nodes.map { |n| node_path(n.name, n.group) }
        active_groups = active_nodes.map(&:group).compact.uniq

        [default_dir, *active_groups].each do |group|
          Dir.glob(::File.join(dir_base, group, "*")).each do |file|
            ::File.delete(file) if ::File.file?(file) && !keep_files.include?(file)
          end
        end
      end
    end
  end
end
