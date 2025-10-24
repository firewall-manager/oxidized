module Oxidized
  module Source
    require "oxidized/source/jsonfile"
    # HTTP源模块
    # 通过HTTP请求从远程API获取设备信息，支持分页和认证
    class HTTP < JSONFile
      # 初始化HTTP源模块
      def initialize
        super
        @cfg = Oxidized.config.source.http
      end

      # 设置HTTP源配置
      # 如果配置为空，则设置默认配置并提示用户编辑配置文件
      def setup
        if @cfg.empty?
          Oxidized.asetus.user.source.http.url       = 'https://url/api'
          Oxidized.asetus.user.source.http.map.name  = 'name'
          Oxidized.asetus.user.source.http.map.model = 'model'
          Oxidized.asetus.save :user

          raise NoConfig, "No source http config, edit #{Oxidized::Config.configfile}"
        end

        # 检查必需属性
        if !@cfg.has_key?('url')
          raise InvalidConfig, "url is a mandatory http source attribute, edit #{Oxidized::Config.configfile}"
        elsif !@cfg.map.has_key?('name')
          raise InvalidConfig, "map/name is a mandatory source attribute, edit #{Oxidized::Config.configfile}"
        end
      end

      require "net/http"
      require "net/https"
      require "uri"
      require "json"

      # 从HTTP API加载节点信息
      # @param node_want [String, nil] 要加载的特定节点名称
      # @return [Array] 节点信息数组
      def load(node_want = nil)
        uri = URI.parse(@cfg.url)
        data = JSON.parse(read_http(uri, node_want))
        node_data = data
        node_data = string_navigate_object(data, @cfg.hosts_location) if @cfg.hosts_location?
        node_data = pagination(data, node_want) if @cfg.pagination?

        transform_json(node_data)
      end

      private

      # 处理分页数据
      # @param data [Hash] 初始数据
      # @param node_want [String, nil] 要加载的特定节点名称
      # @return [Array] 所有页面的节点数据
      def pagination(data, node_want)
        node_data = []
        unless @cfg.pagination_key_name?
          raise Oxidized::OxidizedError,
                "if using pagination, 'pagination_key_name' setting must be set"
        end

        next_key = @cfg.pagination_key_name
        loop do
          node_data += string_navigate_object(data, @cfg.hosts_location) if @cfg.hosts_location?
          break if data[next_key].nil?

          new_uri = URI.parse(data[next_key]) if data.has_key?(next_key)
          data = JSON.parse(read_http(new_uri, node_want))
          node_data += string_navigate_object(data, @cfg.hosts_location) if @cfg.hosts_location?
        end
        node_data
      end

      # 读取HTTP响应
      # @param uri [URI] 请求URI
      # @param node_want [String, nil] 要加载的特定节点名称
      # @return [String] HTTP响应体
      def read_http(uri, node_want)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless @cfg.secure

        # 添加读取超时以处理大量节点的情况（默认值是60秒）
        http.read_timeout = Integer(@cfg.read_timeout) if @cfg.has_key? "read_timeout"

        # 映射请求头
        headers = {}
        @cfg.headers.each do |header, value|
          headers[header] = value
        end

        req_uri = uri.request_uri
        req_uri = "#{req_uri}/#{node_want}" if node_want
        request = Net::HTTP::Get.new(req_uri, headers)
        request.basic_auth(@cfg.user, @cfg.pass) if @cfg.user? && @cfg.pass?
        http.request(request).body
      end
    end
  end
end
