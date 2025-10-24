module Oxidized
  require 'oxidized/model/model'
  require 'oxidized/input/input'
  require 'oxidized/output/output'
  require 'oxidized/source/source'
  # 管理器类
  # 负责动态加载和管理各种模块（输入、输出、源、模型、钩子）
  class Manager
    class << self
      # 加载模块文件
      # @param dir [String] 目录路径
      # @param file [String] 文件名
      # @param namespace [Module] 命名空间
      # @return [Hash, false] 加载的模块哈希或false
      def load(dir, file, namespace)
        require File.join dir, file + '.rb'

        # 在命名空间中搜索要加载的对象
        klass = namespace.constants.find { |const| const.to_s.casecmp(file).zero? }

        return false unless klass

        klass = namespace.const_get klass

        i = klass.new
        i.setup if i.respond_to? :setup
        { file => klass }
      rescue LoadError
        false
      end
    end

    # 各种模块的哈希表
    attr_reader :input, :output, :source, :model, :hook

    # 初始化管理器
    def initialize
      @input  = {}
      @output = {}
      @source = {}
      @model  = {}
      @hook   = {}
    end

    # 添加输入模块
    # @param name [String] 模块名称
    def add_input(name)
      loader @input, Config::INPUT_DIR, "input", name, Oxidized
    end

    # 添加输出模块
    # @param name [String] 模块名称
    def add_output(name)
      loader @output, Config::OUTPUT_DIR, "output", name, Oxidized::Output
    end

    # 添加源模块
    # @param name [String] 模块名称
    def add_source(name)
      loader @source, Config::SOURCE_DIR, "source", name, Oxidized::Source
    end

    # 添加模型模块
    # @param name [String] 模块名称
    def add_model(name)
      loader @model, Config::MODEL_DIR, "model", name, Object
    end

    # 添加钩子模块
    # @param name [String] 模块名称
    def add_hook(name)
      loader @hook, Config::HOOK_DIR, "hook", name, Object
    end

    private

    # 模块加载器
    # 如果本地版本文件存在则加载，否则加载全局版本 - 如果未加载任何内容则返回假值
    # @param hash [Hash] 目标哈希表
    # @param global_dir [String] 全局目录
    # @param local_dir [String] 本地目录
    # @param name [String] 模块名称
    # @param namespace [Module] 命名空间
    def loader(hash, global_dir, local_dir, name, namespace)
      dir   = File.join(Config::ROOT, local_dir)
      map   = Manager.load(dir, name, namespace) if File.exist? File.join(dir, name + ".rb")
      map ||= Manager.load(global_dir, name, namespace)
      hash.merge!(map) if map
    end
  end
end
