module Oxidized
  module Output
    # Git加密输出模块
    # 将设备配置保存到加密的Git仓库中，使用git-crypt进行加密
    class GitCrypt < Output
      using Refinements
      # Git加密操作异常类
      class GitCryptError < OxidizedError; end
      begin
        require 'git'
      rescue LoadError
        raise OxidizedError, 'git not found: sudo gem install git'
      end

      # 提交引用，用于跟踪Git提交
      attr_reader :commitref

      # 初始化Git加密输出模块
      def initialize
        super
        @cfg = Oxidized.config.output.gitcrypt
        @gitcrypt_cmd = "/usr/bin/git-crypt"
        @gitcrypt_init = @gitcrypt_cmd + " init"
        @gitcrypt_unlock = @gitcrypt_cmd + " unlock"
        @gitcrypt_lock = @gitcrypt_cmd + " lock"
        @gitcrypt_adduser = @gitcrypt_cmd + " add-gpg-user --trusted "
      end

      # 设置Git加密输出配置
      # 如果配置为空，则设置默认配置并提示用户编辑配置文件
      def setup
        if @cfg.empty?
          Oxidized.asetus.user.output.gitcrypt.user  = 'Oxidized'
          Oxidized.asetus.user.output.gitcrypt.email = 'o@example.com'
          Oxidized.asetus.user.output.gitcrypt.repo = ::File.join(Config::ROOT, 'oxidized.git')
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

      # 初始化Git加密
      # @param repo [Git::Base] Git仓库对象
      def crypt_init(repo)
        repo.chdir do
          system(@gitcrypt_init)
          @cfg.users.each do |user|
            system("#{@gitcrypt_adduser} #{user}")
          end
          ::File.write(".gitattributes", "* filter=git-crypt diff=git-crypt\n.gitattributes !filter !diff")
          repo.add(".gitattributes")
          repo.commit("Initial commit: crypt all config files")
        end
      end

      # 锁定Git加密仓库
      # @param repo [Git::Base] Git仓库对象
      def lock(repo)
        repo.chdir do
          system(@gitcrypt_lock)
        end
      end

      # 解锁Git加密仓库
      # @param repo [Git::Base] Git仓库对象
      def unlock(repo)
        repo.chdir do
          system(@gitcrypt_unlock)
        end
      end

      # 存储节点配置到加密的Git仓库
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

      # 获取节点配置
      # @param node [Object] 节点对象
      # @param group [String] 组名
      # @return [String, nil] 配置内容或nil
      def fetch(node, group)
        repo, path = yield_repo_and_path(node, group)
        repo = Git.open repo
        unlock repo
        index = repo.index
        # 空仓库？
        raise 'Empty git repo' if ::File.exist?(index.path)

        ::File.read path
        lock repo
      rescue StandardError
        'node not found'
      end

      # 获取给定节点的所有oid修订版本哈希和提交日期
      # @param node [Object] 节点对象
      # @param group [String] 组名
      # @return [Array] 版本信息数组
      def version(node, group)
        repo, path = yield_repo_and_path(node, group)

        repo = Git.open repo
        unlock repo
        walker = repo.log.path(path)
        i = -1
        tab = []
        walker.each do |commit|
          hash = {}
          # 我们保留:date以兼容oxidized-web <= 0.15.1
          hash[:date] = commit.date.to_s
          # 日期作为Time实例，在oxidized-web中更灵活
          hash[:time] = commit.date
          hash[:oid] = commit.objectish
          hash[:author] = commit.author
          hash[:message] = commit.message
          tab[i += 1] = hash
        end
        walker.reset
        tab
      rescue StandardError
        'node not found'
      end

      # 获取特定修订版本的blob内容
      # @param node [Object] 节点对象
      # @param group [String] 组名
      # @param oid [String] 对象ID
      # @return [String] 版本内容
      def get_version(node, group, oid)
        repo, path = yield_repo_and_path(node, group)
        repo = Git.open repo
        unlock repo
        repo.gtree(oid).files[path].contents
      rescue StandardError
        'version not found'
      ensure
        lock repo
      end

      # 获取两个修订版本之间差异的补丁哈希和统计信息（添加和删除的行数）
      # @param node [Object] 节点对象
      # @param group [String] 组名
      # @param oid1 [String] 第一个对象ID
      # @param oid2 [String] 第二个对象ID
      # @return [Hash] 差异信息
      def get_diff(node, group, oid1, oid2)
        diff_commits = nil
        repo, _path = yield_repo_and_path(node, group)
        repo = Git.open repo
        unlock repo
        commit = repo.gcommit(oid1)

        if oid2
          commit_old = repo.gcommit(oid2)
          diff = repo.diff(commit_old, commit)
          stats = [diff.stats[:files][node.name][:insertions], diff.stats[:files][node.name][:deletions]]
          diff.each do |patch|
            if /#{node.name}\s+/ =~ patch.patch.to_s.lines.first
              diff_commits = { patch: patch.patch.to_s, stat: stats }
              break
            end
          end
        else
          stat = commit.parents[0].diff(commit).stats
          stat = [stat[:files][node.name][:insertions], stat[:files][node.name][:deletions]]
          patch = commit.parents[0].diff(commit).patch
          diff_commits = { patch: patch, stat: stat }
        end
        lock repo
        diff_commits
      rescue StandardError
        'no diffs'
      ensure
        lock repo
      end

      private

      # 获取仓库和路径
      # @param node [Object] 节点对象
      # @param group [String] 组名
      # @return [Array] [仓库路径, 文件路径]
      def yield_repo_and_path(node, group)
        repo = node.repo
        path = node.name

        path = "#{group}/#{node.name}" if group && @cfg.single_repo?

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
          update_repo repo, file, data, @msg, @user, @email
        rescue Git::GitExecuteError, ArgumentError => e
          logger.debug "open_error #{e} #{file}"
          begin
            grepo = Git.init repo
            crypt_init grepo
          rescue StandardError => create_error
            raise GitCryptError, "first '#{e.message}' was raised while opening git repo, then " \
                                 "'#{create_error.message}' was while trying to create git repo"
          end
          retry
        end
      end

      # 更新仓库中的文件内容
      # @param repo [String] 仓库路径
      # @param file [String] 文件名
      # @param data [String] 数据内容
      # @param msg [String] 提交消息
      # @param user [String] 用户名
      # @param email [String] 邮箱
      def update_repo(repo, file, data, msg, user, email)
        grepo = Git.open repo
        grepo.config('user.name', user)
        grepo.config('user.email', email)
        grepo.chdir do
          unlock grepo
          ::File.write(file, data)
          grepo.add(file)
          if grepo.status[file].nil? || !grepo.status[file].type.nil?
            grepo.commit(msg)
            @commitref = grepo.log(1).first.objectish
            true
          end
          lock grepo
        end
      end
    end
  end
end
