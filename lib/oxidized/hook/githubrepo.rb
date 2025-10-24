require 'rugged'

# GitHub仓库钩子模块
# 将本地Git仓库推送到远程GitHub仓库，支持多种认证方式
class GithubRepo < Oxidized::Hook
  # 验证配置参数
  # 检查必需的配置项是否存在
  def validate_cfg!
    raise KeyError, 'hook.remote_repo is required' unless cfg.has_key?('remote_repo')
  end

  # 运行钩子
  # 将本地Git仓库推送到远程GitHub仓库
  # @param ctx [Object] 钩子上下文，包含事件和节点信息
  def run_hook(ctx)
    unless ctx.node
      logger.error 'GithubRepo.run_hook: no node provided'
      return
    end

    unless ctx.node.repo
      logger.error "Oxidized output is not git, can't push to remote"
      return
    end
    repo  = Rugged::Repository.new(ctx.node.repo)
    creds = credentials(ctx.node)
    url   = remote_repo(ctx.node)

    if url.nil? || url.empty?
      logger.error "No repository defined for #{ctx.node.group}/#{ctx.node.name}"
      return
    end

    logger.info "Pushing local repository(#{repo.path}) to remote: #{url}"

    # 设置远程仓库
    if repo.remotes['origin'].nil?
      repo.remotes.create('origin', url)
    elsif repo.remotes['origin'].url != url
      repo.remotes.set_url('origin', url)
    end
    remote = repo.remotes['origin']

    begin
      fetch_and_merge_remote(repo, creds)
      remote.push([repo.head.name], credentials: creds)
    rescue Rugged::NetworkError => e
      if e.message == 'unsupported URL protocol'
        logger.warn "Rugged does not support the git URL '#{url}'."
        unless Rugged.features.include?(:ssh)
          logger.warn "Note: Rugged isn't installed with ssh support. You may need " \
                      '"gem install rugged -- --with-ssh"'
        end
      end
      # 重新抛出异常给调用方法
      raise
    end
  end

  # 获取并合并远程分支
  # @param repo [Rugged::Repository] Git仓库对象
  # @param creds [Object] 认证凭据
  def fetch_and_merge_remote(repo, creds)
    result = repo.fetch('origin', [repo.head.name], credentials: creds)
    logger.debug result.inspect

    their_branch = remote_branch(repo)

    unless their_branch
      logger.debug 'remote branch does not exist yet, nothing to merge'
      return
    end

    result = repo.merge_analysis(their_branch.target_id)

    if result.include? :up_to_date
      logger.debug 'nothing to merge'
      return
    end

    logger.debug "merging fetched branch #{their_branch.name}"

    merge_index = repo.merge_commits(repo.head.target_id, their_branch.target_id)

    if merge_index.conflicts?
      logger.warn "Conflicts detected, skipping Rugged::Commit.create"
      return
    end

    Rugged::Commit.create(repo,
                          parents:    [repo.head.target, their_branch.target],
                          tree:       merge_index.write_tree(repo),
                          message:    "Merge remote-tracking branch '#{their_branch.name}'",
                          update_ref: "HEAD")
  end

  private

  # 创建认证凭据
  # 支持用户名密码、SSH密钥和SSH代理认证
  # @param node [Object] 节点对象
  # @return [Proc] 认证过程对象
  def credentials(node)
    Proc.new do |_url, username_from_url, _allowed_types| # rubocop:disable Style/Proc
      git_user = cfg.has_key?('username') ? cfg.username : (username_from_url || 'git')
      if cfg.has_key?('password')
        logger.debug "Authenticating using username and password as '#{git_user}'"
        Rugged::Credentials::UserPassword.new(username: git_user, password: cfg.password)
      elsif cfg.has_key?('privatekey')
        pubkey = cfg.has_key?('publickey') ? cfg.publickey : nil
        logger.debug "Authenticating using ssh keys as '#{git_user}'"
        rugged_sshkey(git_user: git_user, privkey: cfg.privatekey, pubkey: pubkey)
      elsif cfg.has_key?('remote_repo') &&
            cfg.remote_repo.has_key?(node.group) &&
            cfg.remote_repo[node.group].has_key?('privatekey')
        pubkey = cfg.remote_repo[node.group].has_key?('publickey') ? cfg.remote_repo[node.group].publickey : nil
        logger.debug "Authenticating using ssh keys as '#{git_user}' for '#{node.group}/#{node.name}'"
        rugged_sshkey(git_user: git_user, privkey: cfg.remote_repo[node.group].privatekey, pubkey: pubkey)
      else
        logger.debug "Authenticating using ssh agent as '#{git_user}'"
        Rugged::Credentials::SshKeyFromAgent.new(username: git_user)
      end
    end
  end

  # 创建SSH密钥认证凭据
  # @param args [Hash] 参数哈希，包含用户名、私钥和公钥路径
  # @return [Rugged::Credentials::SshKey] SSH密钥认证对象
  def rugged_sshkey(args = {})
    git_user   = args[:git_user]
    privkey    = args[:privkey]
    pubkey     = args[:pubkey] || (privkey + '.pub')
    Rugged::Credentials::SshKey.new(username:   git_user,
                                    publickey:  File.expand_path(pubkey),
                                    privatekey: File.expand_path(privkey),
                                    passphrase: ENV.fetch("OXIDIZED_SSH_PASSPHRASE", nil))
  end

  # 获取远程仓库URL
  # @param node [Object] 节点对象
  # @return [String, nil] 远程仓库URL
  def remote_repo(node)
    if node.group.nil? || cfg.remote_repo.is_a?(String)
      cfg.remote_repo
    elsif cfg.remote_repo[node.group].is_a?(String)
      cfg.remote_repo[node.group]
    elsif cfg.remote_repo[node.group].url.is_a?(String)
      cfg.remote_repo[node.group].url
    end
  end

  # 返回远程分支的Rugged::Branch对象，如果不存在则返回nil
  # @param repo [Rugged::Repository] Git仓库对象
  # @return [Rugged::Branch, nil] 远程分支对象
  def remote_branch(repo)
    head_branch = repo.branches[repo.head.name]
    repo.branches['origin/' + head_branch.name]
  end
end
