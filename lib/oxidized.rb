require 'fileutils'
require 'refinements'
require 'semantic_logger'

# Oxidized 主模块
# 网络设备配置备份系统的核心模块，提供全局配置和错误处理
module Oxidized
  # Oxidized 异常基类
  # 所有 Oxidized 相关异常都继承自此类
  class OxidizedError < StandardError; end
  include SemanticLogger::Loggable

  # Oxidized 根目录路径
  # 用于定位配置文件和资源文件
  Directory = File.expand_path(File.join(File.dirname(__FILE__), '../'))

  # 加载核心模块
  require 'oxidized/version'      # 版本管理模块
  require 'oxidized/config'        # 配置管理模块
  require 'oxidized/config/vars'   # 配置变量模块
  require 'oxidized/worker'        # 工作器模块
  require 'oxidized/nodes'         # 节点集合模块
  require 'oxidized/manager'       # 模块管理器
  require 'oxidized/hook'          # 钩子系统模块
  require 'oxidized/signals'       # 信号处理模块
  require 'oxidized/core'          # 核心模块
  require 'oxidized/logger'        # 日志系统模块

  # 获取配置对象
  # @return [Asetus] 配置对象实例
  def self.asetus
    @@asetus
  end

  # 设置配置对象
  # @param val [Asetus] 配置对象实例
  def self.asetus=(val)
    @@asetus = val
  end

  # 获取配置哈希
  # @return [Hash] 配置哈希表
  def self.config
    asetus.cfg
  end
end
