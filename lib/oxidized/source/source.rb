module Oxidized
  module Source
    # 源模块基类
    # 提供所有源模块的通用功能，包括模型映射、组映射和变量插值
    class Source
      # 配置缺失异常类
      class NoConfig < OxidizedError; end

      # 初始化源模块
      # 加载模型映射和组映射配置
      def initialize
        @model_map = Oxidized.config.model_map || {}
        @group_map = Oxidized.config.group_map || {}
      end

      # #map_model和#map_group的通用代码
      # @param map_hash [Hash] 映射哈希表
      # @param original_value [String] 原始值
      # @return [String] 映射后的值或原始值
      def map_value(map_hash, original_value)
        map_hash.each do |key, new_value|
          mthd = key.instance_of?(Regexp) ? :match : :eql?
          return new_value if original_value.send(mthd, key)
        end
        original_value
      end

      # 在配置中搜索模型匹配并返回它
      # 如果没有找到匹配，返回原始模型
      #
      # 模型可以与字符串或正则表达式匹配：
      #
      # model_map:
      #   cisco: ios
      #   juniper: junos
      #   !ruby/regexp /procurve/: procurve
      # @param model [String] 原始模型名称
      # @return [String] 映射后的模型名称
      def map_model(model)
        map_value(@model_map, model)
      end

      # 在配置中搜索组匹配并返回它
      # 如果没有找到匹配，返回原始组
      #
      # 组可以与字符串或正则表达式匹配：
      #
      # group_map:
      #   alias1: groupA
      #   alias2: groupA
      #   alias3: groupB
      #   alias4: groupB
      #   !ruby/regexp /specialgroup/: groupS
      #   aliasN: groupZ
      # @param group [String] 原始组名称
      # @return [String] 映射后的组名称
      def map_group(group)
        map_value(@group_map, group)
      end

      # 节点变量插值处理
      # 将字符串形式的特殊值转换为相应的Ruby对象
      # @param var [String] 变量值
      # @return [Object] 转换后的值
      def node_var_interpolate(var)
        case var
        when "nil"   then nil
        when "false" then false
        when "true"  then true
        else var
        end
      end

      private

      # 打开文件，支持GPG加密文件
      # @return [File, String] 文件对象或解密后的内容
      def open_file
        file = File.expand_path(@cfg.file)
        if @cfg.gpg?
          crypto = GPGME::Crypto.new password: @cfg.gpg_password
          crypto.decrypt(File.open(file)).to_s
        else
          File.open(file)
        end
      end

      # 使用字符串路径导航对象
      # 支持点记法和数组索引，如 "data.hosts[0].name"
      # @param object [Object] 要导航的对象
      # @param wants [String] 导航路径字符串
      # @return [Object] 导航到的对象
      def string_navigate_object(object, wants)
        wants = wants.split(".").map do |want|
          head, match, _tail = want.partition(/\[\d+\]/)
          match.empty? ? head : [head, match[1..-2].to_i]
        end
        wants.flatten.each do |want|
          object = object[want] if object.respond_to? :each
        end
        object
      end
    end
  end
end
