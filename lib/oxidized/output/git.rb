module Oxidized
  module Output
    # Git输出模块
    # 将设备配置保存到Git仓库中，支持版本控制和历史记录
    class Git < Output
      using Refinements

      # Git操作异常类
      class GitError < OxidizedError; end
      begin
        require 'rugged'
      rescue LoadError
        raise OxidizedError, 'rugged not found: sudo gem install rugged'
      end

      # 提交引用，用于跟踪Git提交
      attr_reader :commitref

      # 初始化Git输出模块
      def initialize
        super
        @cfg = Oxidized.config.output.git
      end

      # 设置Git输出配置
      # 如果配置为空，则设置默认配置并提示用户编辑配置文件
      def setup
        if @cfg.empty?
          Oxidized.asetus.user.output.git.user  = 'Oxidized'
          Oxidized.asetus.user.output.git.email = 'o@example.com'
          Oxidized.asetus.user.output.git.repo = ::File.join(Config::ROOT, 'oxidized.git')
          Oxidized.asetus.save :user
          raise NoConfig, "no output git config, edit #{Oxidized::Config.configfile}"
        end

        if @cfg.repo.respond_to?(:each)
          @cfg.repo.each do |group, repo|
            @cfg.repo["#{group}="] = ::File.expand_path repo
          end
        else
          @cfg.repo = ::File.expand_path @cfg.repo
        end
      end

      # 存储节点配置到Git仓库
      # @param file [String] 文件名
      # @param outputs [Oxidized::Models::Outputs] 输出对象
      # @param opt [Hash] 选项哈希，包含消息、用户、邮箱等信息
      def store(file, outputs, opt = {})
        @msg   = opt[:msg]
        @user  = opt[:user]  || @cfg.user
        @email = opt[:email] || @cfg.email
        @opt   = opt
        @commitref = nil
        repo = @cfg.repo

        # 处理每种输出类型
        outputs.types.each do |type|
          type_cfg = ''
          type_repo = ::File.join(::File.dirname(repo), type + '.git')
          outputs.type(type).each do |output|
            (type_cfg << output; next) unless output.name # rubocop:disable Style/Semicolon
            type_file = file + '--' + output.name
            if @cfg.type_as_directory?
              type_file = type + '/' + type_file
              type_repo = repo
            end
            update type_repo, type_file, output
          end
          update type_repo, file, type_cfg
        end

        update repo, file, outputs.to_cfg
      end

      # 获取组/节点名称的配置
      #
      # #fetch由Nodes#fetch调用
      # Nodes#fetch每次都会创建新的Output对象，因此不容易在内存中缓存仓库索引
      # 但由于我们在#update_repo中保持磁盘上的仓库索引是最新的，
      # 我们可以从磁盘读取而不是每次都重建
      def fetch(node, group)
        repo, path = yield_repo_and_path(node, group)
        repo = Rugged::Repository.new repo
        # 从磁盘读取索引
        index = repo.index

        repo.read(index.get(path)[:oid]).data
      rescue StandardError
        'node not found'
      end

      # 获取给定节点的所有oid修订版本哈希和提交日期
      #
      # 由Nodes#version调用
      def version(node, group)
        repo_path, node_path = yield_repo_and_path(node, group)
        self.class.hash_list(node_path, repo_path)
      rescue StandardError
        'node not found'
      end

      # 获取特定修订版本的blob内容
      def get_version(node, group, oid)
        repo, path = yield_repo_and_path(node, group)
        repo = Rugged::Repository.new repo
        repo.blob_at(oid, path).content
      rescue StandardError
        'version not found'
      end

      # 获取两个修订版本之间差异的补丁哈希和统计信息（添加和删除的行数）
      def get_diff(node, group, oid1, oid2)
        diff_commits = nil
        repo, = yield_repo_and_path(node, group)
        repo = Rugged::Repository.new repo
        commit = repo.lookup(oid1)

        if oid2
          commit_old = repo.lookup(oid2)
          diff = repo.diff(commit_old, commit)
          diff.each do |patch|
            if /#{node.name}\s+/ =~ patch.to_s.lines.first
              diff_commits = { patch: patch.to_s, stat: patch.stat }
              break
            end
          end
        else
          stat = commit.parents[0].diff(commit).stat
          stat = [stat[1], stat[2]]
          patch = commit.parents[0].diff(commit).patch
          diff_commits = { patch: patch, stat: stat }
        end

        diff_commits
      rescue StandardError
        'no diffs'
      end

      # 返回仓库repo_path中node_path的oid列表
      def self.hash_list(node_path, repo_path)
        update_cache(repo_path)
        @gitcache[repo_path][:nodes][node_path] || []
      end

      # 更新@gitcache，一个类实例变量，通过独立于对象实例保存缓存来确保持久性
      def self.update_cache(repo_path)
        # 将缓存初始化为类实例变量
        @gitcache ||= {}
        # 当single_repo == false时，我们有多个仓库
        unless @gitcache[repo_path]
          @gitcache[repo_path] = {}
          @gitcache[repo_path][:nodes] = {}
          @gitcache[repo_path][:last_commit] = nil
        end

        repo = Rugged::Repository.new repo_path

        walker = Rugged::Walker.new(repo)
        walker.sorting(Rugged::SORT_DATE)
        walker.push(repo.head.target.oid)

        # 我们将提交存储到临时缓存中。它将被前置到@gitcache以保持提交的顺序
        cache = {}
        walker.each do |commit|
          if commit.oid == @gitcache[repo_path][:last_commit]
            # 我们已经到达了最后缓存的提交，所以完成了
            break
          end

          commit.diff.each_delta do |delta|
            next unless delta.added? || delta.modified?

            hash = {}
            # 我们保留:date以兼容oxidized-web <= 0.15.1
            hash[:date] = commit.time.to_s
            # 日期作为Time实例，在oxidized-web中更灵活
            hash[:time] = commit.time
            hash[:oid] = commit.oid
            hash[:author] = commit.author
            hash[:message] = commit.message

            filename = delta.new_file[:path]
            if cache[filename]
              cache[filename].append hash
            else
              cache[filename] = [hash]
            end
          end
        end

        cache.each_pair do |filename, hashlist|
          if @gitcache[repo_path][:nodes][filename]
            # 使用展开操作符(*)应该是可以的，因为hashlist在处理增量时不应该很大
            @gitcache[repo_path][:nodes][filename].prepend(*hashlist)
          else
            @gitcache[repo_path][:nodes][filename] = hashlist
          end
        end

        # 存储最近的提交
        @gitcache[repo_path][:last_commit] = repo.head.target.oid
      end

      # 清除缓存（目前仅在单元测试中使用）
      def self.clear_cache
        @gitcache = nil
      end

      # 清理过时的节点
      # 从Git仓库中删除不再活跃的节点配置文件
      def self.clean_obsolete_nodes(active_nodes)
        git_config = Oxidized.config.output.git
        repo_path = git_config.repo

        unless git_config.single_repo?
          logger.warn "clean_obsolete_nodes is not implemented for " \
                      "multiple git repositories"
          return
        end

        if git_config.type_as_directory?
          logger.warn "clean_obsolete_nodes is not implemented for output " \
                      "types as a directory within the git repository"
          return
        end

        # 仓库可能在第一次运行时不存在
        return unless ::File.directory?(repo_path)

        repo = Rugged::Repository.new repo_path
        return if repo.empty?

        keep_files = active_nodes.map do |n|
          n.group ? ::File.join(n.group, n.name) : n.name
        end

        tree = repo.last_commit.tree
        files_to_delete = []

        tree.walk_blobs do |root, entry|
          file_path = root.empty? ? entry[:name] : ::File.join(root, entry[:name])
          files_to_delete << file_path unless keep_files.include?(file_path)
        end

        return if files_to_delete.empty?

        logger.info "clean_obsolete_nodes: removing " \
                    "#{files_to_delete.size} obsolete configs"
        index = repo.index

        files_to_delete.each { |file_path| index.remove(file_path) }

        repo.config['user.name']  = git_config.user
        repo.config['user.email'] = git_config.email
        Rugged::Commit.create(
          repo,
          tree:       index.write_tree(repo),
          message:    "Removing #{files_to_delete.size} obsolete configs",
          parents:    [repo.head.target].compact,
          update_ref: 'HEAD'
        )

        index.write
      end

      private

      # 获取仓库和路径
      # @param node [Object] 节点对象
      # @param group [String] 组名
      # @return [Array] [仓库路径, 文件路径]
      def yield_repo_and_path(node, group)
        repo = node.repo
        path = node.name

        path = "#{group}/#{node.name}" if group && !group.empty? && @cfg.single_repo?

        [repo, path]
      end

      # 更新仓库中的文件
      # @param repo [String] 仓库路径
      # @param file [String] 文件名
      # @param data [String] 数据内容
      def update(repo, file, data)
        return if data.empty?

        if @opt[:group]
          if @cfg.single_repo?
            file = ::File.join @opt[:group], file
          else
            repo = if repo.is_a?(::String)
                     ::File.join ::File.dirname(repo), @opt[:group] + '.git'
                   else
                     repo[@opt[:group]]
                   end
          end
        end

        begin
          repo = Rugged::Repository.new repo
          update_repo repo, file, data
        rescue Rugged::OSError, Rugged::RepositoryError => e
          begin
            Rugged::Repository.init_at repo, :bare
          rescue StandardError => create_error
            raise GitError, "first '#{e.message}' was raised while opening git repo, then '#{create_error.message}' " \
                            "was while trying to create git repo"
          end
          retry
        end
      end

      # 将数据上传到仓库repo中的文件
      #
      # update_repo在磁盘上缓存索引。索引通常在工作目录中使用，
      # 而不是在裸仓库中，这会让用户感到困惑。
      # 替代方案是每次都重建索引，这有点耗时。
      # 在内存中缓存索引很困难，因为每次调用#store时都会创建新的Output对象
      def update_repo(repo, file, data) # rubocop:disable Naming/PredicateMethod
        oid_old = repo.blob_at(repo.head.target_id, file) rescue nil
        return false if oid_old && (oid_old.content.b == data.b)

        oid = repo.write data, :blob
        # 从磁盘读取索引
        index = repo.index
        index.add path: file, oid: oid, mode: 0o100644

        repo.config['user.name']  = @user
        repo.config['user.email'] = @email
        @commitref = Rugged::Commit.create(repo,
                                           tree:       index.write_tree(repo),
                                           message:    @msg,
                                           parents:    repo.empty? ? [] : [repo.head.target].compact,
                                           update_ref: 'HEAD')

        index.write
        true
      end
    end
  end
end
