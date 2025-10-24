module Oxidized
  require 'resolv'
  require_relative 'node/stats'
  # 方法未找到异常
  class MethodNotFound < OxidizedError; end
  # 模型未找到异常
  class ModelNotFound  < OxidizedError; end

  # 节点类
  # 表示一个网络设备节点，包含所有配置获取和存储相关的信息
  class Node
    include SemanticLogger::Loggable

    # 节点属性：名称、IP、模型、输入、输出、组、认证、提示符、超时、变量、最后任务、仓库
    attr_reader :name, :ip, :model, :input, :output, :group, :auth, :prompt, :timeout, :vars, :last, :repo
    # 可访问属性：运行状态、用户、邮箱、消息、来源、统计、重试次数、错误类型、错误原因
    attr_accessor :running, :user, :email, :msg, :from, :stats, :retry, :err_type, :err_reason
    alias running? running

    # 初始化节点
    # opt是包含节点参数的哈希表（:name, :group, :ip等）
    # @param opt [Hash] 节点参数字哈希
    def initialize(opt)
      logger.debug 'resolving DNS for %s...' % opt[:name]
      # 如果提供了带前缀的IP地址，去掉前缀，因为IPAddr会将其转换为网络地址
      ip_addr, = opt[:ip].to_s.split("/")
      logger.debug 'IPADDR %s' % ip_addr.to_s
      @name = opt[:name]
      @ip = IPAddr.new(ip_addr).to_s rescue nil
      @ip ||= Resolv.new.getaddress(@name) if Oxidized.config.resolve_dns?
      @ip ||= @name
      @group = opt[:group]
      @model = resolve_model opt
      @input = resolve_input opt
      @output = resolve_output opt
      @auth = resolve_auth opt
      @prompt = resolve_prompt opt
      @timeout = resolve_timeout opt
      @vars = opt[:vars] || {}
      @stats = Stats.new
      @retry = 0
      @repo = resolve_repo opt
      @err_type = nil
      @err_reason = nil

      # 模型实例需要访问节点实例
      @model.node = self
    end

    # 运行节点配置获取
    # 尝试所有可用的输入方法获取设备配置
    # @return [Array] [状态, 配置] 状态和配置内容
    def run
      status = :fail
      config = nil
      @input.each do |input|
        # 如果模型缺少配置块，不要尝试输入，我们可能需要强配置到类名映射
        cfg_name = input.to_s.split('::').last.downcase
        next unless @model.cfg[cfg_name] && (not @model.cfg[cfg_name].empty?)

        @model.input = input = input.new
        if (config = run_input(input))
          logger.debug "#{input.class.name} ran for #{name} successfully"
          status = :success
          break
        else
          logger.debug "#{input.class.name} failed for #{name}"
          status = :no_connection
        end
      end
      logger.error "No suitable input found for #{name}" unless @model.input

      @model.input = nil
      [status, config]
    end

    # 运行输入方法
    # 执行具体的输入连接和配置获取，处理各种异常情况
    # @param input [Object] 输入对象
    # @return [String, false] 配置内容或false
    def run_input(input)
      rescue_fail = {}
      [input.class::RESCUE_FAIL, input.class.superclass::RESCUE_FAIL].each do |hash|
        hash.each do |level, errors|
          errors.each do |err|
            rescue_fail[err] = level
          end
        end
      end
      begin
        input.connect(self) && input.get
      rescue *rescue_fail.keys => err
        resc = ''
        unless (level = rescue_fail[err.class])
          resc  = err.class.ancestors.find { |e| rescue_fail.has_key?(e) }
          level = rescue_fail[resc]
          resc  = " (rescued #{resc})"
        end
        logger.send(level, '%s raised %s%s with msg "%s"' % [ip, err.class, resc, err.message])
        @err_type = err.class.to_s
        @err_reason = err.message.to_s
        false
      rescue StandardError => e
        # 在调试模式下发送消息，以防我们无法创建崩溃文件
        logger.error "#{ip} raised #{e.class} with msg #{e.message}, creating crashfile"
        unless Oxidized.config.crash.directory?
          logger.error "Cannot create crashfile for exception", e
          return false
        end

        crashdir  = Oxidized.config.crash.directory
        crashfile = Oxidized.config.crash.hostnames? ? name : ip.to_s
        FileUtils.mkdir_p(crashdir) unless File.directory?(crashdir)

        File.open File.join(crashdir, crashfile), 'w' do |fh|
          fh.puts Time.now.utc
          fh.puts e.message + ' [' + e.class.to_s + ']'
          fh.puts '-' * 50
          fh.puts e.backtrace
        end
        logger.error '%s raised %s with msg "%s", %s saved' % [ip, e.class, e.message, crashfile]
        @err_type = e.class.to_s
        @err_reason = e.message.to_s
        false
      end
    end

    # 序列化节点信息
    # 将节点信息转换为哈希表，用于API返回
    # @return [Hash] 节点信息哈希表
    def serialize
      h = {
        name:      @name,
        full_name: @name,
        ip:        @ip,
        group:     @group,
        model:     @model.class.to_s,
        last:      nil,
        vars:      @vars,
        mtime:     @stats.mtime
      }
      h[:full_name] = [@group, @name].join('/') if @group
      if @last
        h[:last] = {
          start:  @last.start,
          end:    @last.end,
          status: @last.status,
          time:   @last.time
        }
      end
      h
    end

    # 任务结构体
    JobStruct = Struct.new(:start, :end, :status, :time)
    
    # 设置最后任务
    # @param job [Job, nil] 任务对象
    def last=(job)
      if job
        @last = JobStruct.new(job.start, job.end, job.status, job.time)
      else
        @last = nil
      end
    end

    # 重置节点状态
    # 清除用户信息、邮箱、消息、来源和重试次数
    def reset
      @user = @email = @msg = @from = nil
      @retry = 0
    end

    # 标记节点为已修改
    # 更新统计信息的修改时间
    def modified
      @stats.update_mtime
    end

    private

    # 解析提示符配置
    # @param opt [Hash] 节点选项
    # @return [Regexp] 提示符正则表达式
    def resolve_prompt(opt)
      opt[:prompt] || @model.prompt || Oxidized.config.prompt
    end

    # 解析超时配置
    # @param opt [Hash] 节点选项
    # @return [Integer] 超时时间
    def resolve_timeout(opt)
      resolve_key :timeout, opt, Oxidized.config.timeout
    end

    # 解析认证配置
    # @param opt [Hash] 节点选项
    # @return [Hash] 认证信息哈希表
    def resolve_auth(opt)
      # 解析配置的用户名/密码
      {
        username: resolve_key(:username, opt),
        password: resolve_key(:password, opt)
      }
    end

    # 解析输入方法配置
    # @param opt [Hash] 节点选项
    # @return [Array] 输入方法数组
    def resolve_input(opt)
      inputs = resolve_key :input, opt, Oxidized.config.input.default
      inputs.split(',').map do |input|
        input.strip!
        unless Oxidized.mgr.input[input]
          Oxidized.mgr.add_input(input) || raise(MethodNotFound, "#{input} not found for node #{ip}")
        end

        Oxidized.mgr.input[input]
      end
    end

    # 解析输出方法配置
    # @param opt [Hash] 节点选项
    # @return [Object] 输出方法对象
    def resolve_output(opt)
      output = resolve_key :output, opt, Oxidized.config.output.default
      unless Oxidized.mgr.output[output]
        Oxidized.mgr.add_output(output) || raise(MethodNotFound,
                                                 "#{output} not found for node #{ip}")
      end

      Oxidized.mgr.output[output]
    end

    # 解析模型配置
    # @param opt [Hash] 节点选项
    # @return [Object] 模型实例
    def resolve_model(opt)
      model = resolve_key :model, opt
      unless Oxidized.mgr.model[model]
        logger.debug "Loading model #{model.inspect}"
        Oxidized.mgr.add_model(model) || raise(ModelNotFound, "#{model} not found for node #{ip}")
      end
      Oxidized.mgr.model[model].new
    end

    # 解析仓库配置
    # @param opt [Hash] 节点选项
    # @return [String, nil] 仓库路径
    def resolve_repo(opt)
      type = git_type opt
      return nil unless type

      remote_repo = Oxidized.config.output.send(type).repo
      if remote_repo.is_a?(::String)
        if Oxidized.config.output.send(type).single_repo? || @group.nil?
          remote_repo
        else
          File.join(File.dirname(remote_repo), @group + '.git')
        end
      else
        remote_repo[@group]
      end
    end

    # 解析配置键值
    # 按优先级解析配置：节点 -> 组特定模型 -> 组 -> 模型 -> 全局传递 -> 全局
    # 其中节点具有最高优先级（如果定义，则覆盖其他值）
    # @param key [Symbol, String] 配置键
    # @param opt [Hash] 节点选项
    # @param global [Object, nil] 全局默认值
    # @return [Object] 解析后的值
    def resolve_key(key, opt, global = nil)
      key_sym = key.to_sym
      key_str = key.to_s
      model_name = @model.class.name.to_s.downcase
      logger.debug "resolving node key '#{key}', with passed global value of '#{global}' " \
                   "and node value '#{opt[key_sym]}'"

      # 节点级别
      if opt[key_sym]
        value = opt[key_sym]
        logger.debug "setting node key '#{key}' to value '#{value}' from node"

      # 组特定模型级别
      elsif Oxidized.config.groups.has_key?(@group) &&
            Oxidized.config.groups[@group].models.has_key?(model_name) &&
            Oxidized.config.groups[@group].models[model_name].has_key?(key_str)
        value = Oxidized.config.groups[@group].models[model_name][key_str]
        logger.debug "setting node key '#{key}' to value '#{value}' from model in group"

      # 组级别
      elsif Oxidized.config.groups.has_key?(@group) && Oxidized.config.groups[@group].has_key?(key_str)
        value = Oxidized.config.groups[@group][key_str]
        logger.debug "setting node key '#{key}' to value '#{value}' from group"

      # 模型级别
      elsif Oxidized.config.models.has_key?(model_name) && Oxidized.config.models[model_name].has_key?(key_str)
        value = Oxidized.config.models[model_name][key_str]
        logger.debug "setting node key '#{key}' to value '#{value}' from model"

      # 全局传递值
      elsif global
        value = global
        logger.debug "setting node key '#{key}' to value '#{value}' from passed global value"

      # 全局级别
      elsif Oxidized.config.has_key?(key_str)
        value = Oxidized.config[key_str]
        logger.debug "setting node key '#{key}' to value '#{value}' from global"
      end
      value
    end

    # 检查是否为Git类型输出
    # @param opt [Hash] 节点选项
    # @return [String, nil] Git类型或nil
    def git_type(opt)
      type = opt[:output] || Oxidized.config.output.default
      return nil unless type[0..2] == "git"

      type
    end
  end
end
