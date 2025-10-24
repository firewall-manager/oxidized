# frozen_string_literal: true

module Oxidized
  # Oxidized版本号
  VERSION = '0.34.3'
  # 完整版本号（包含Git信息）
  VERSION_FULL = '0.34.3'
  
  # 设置版本号
  # 从Git仓库获取版本信息并更新常量
  # @return [Boolean] 是否成功设置版本号
  def self.version_set
    version_full = %x(git describe --tags).chop rescue ""
    version      = %x(git describe --tags --abbrev=0).chop rescue ""

    return false unless [version, version_full].none?(&:empty?)

    Oxidized.send(:remove_const, :VERSION)
    Oxidized.send(:remove_const, :VERSION_FULL)
    const_set(:VERSION, version)
    const_set(:VERSION_FULL, version_full)
    file = File.readlines(__FILE__)
    file[3] = "  VERSION = '%s'\n" % VERSION
    file[4] = "  VERSION_FULL = '%s'\n" % VERSION_FULL
    File.write(__FILE__, file.join)
  end
end
