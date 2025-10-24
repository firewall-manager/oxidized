module Oxidized
  module Output
    # HTTP输出模块
    # 将设备配置通过HTTP POST请求发送到远程服务器
    class Http < Output
      # 提交引用，用于跟踪HTTP请求
      attr_reader :commitref

      # 初始化HTTP输出模块
      def initialize
        super
        @cfg = Oxidized.config.output.http
      end

      # 设置HTTP输出配置
      # 如果配置为空，则设置默认配置并提示用户编辑配置文件
      def setup
        return unless @cfg.empty?

        Oxidized.asetus.user.output.http.user = 'Oxidized'
        Oxidized.asetus.user.output.http.pasword = 'secret'
        Oxidized.asetus.user.output.http.url = 'http://localhost/web-api/oxidized'
        Oxidized.asetus.save :user
        raise NoConfig, "no output http config, edit #{Oxidized::Config.configfile}"
      end

      require "net/http"
      require "uri"
      require "json"

      # 存储节点配置到HTTP服务器
      # @param node [Object] 节点对象
      # @param outputs [Oxidized::Models::Outputs] 输出对象
      # @param opt [Hash] 选项哈希，包含消息、用户、邮箱等信息
      def store(node, outputs, opt = {})
        @commitref = nil
        uri = URI.parse @cfg.url
        http = Net::HTTP.new uri.host, uri.port
        # http.use_ssl = true if uri.scheme = 'https'
        req = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
        req.basic_auth @cfg.user, @cfg.password
        req.body = generate_json(node, outputs, opt)
        response = http.request req

        case response.code.to_i
        when 200 || 201
          logger.info "Configuration http backup complete for #{node}"
          p [:success]
        when (400..499)
          logger.info "Configuration http backup for #{node} failed status: #{response.body}"
          p [:bad_request]
        when (500..599)
          p [:server_problems]
          logger.info "Configuration http backup for #{node} failed status: #{response.body}"
        end
      end

      private

      # 生成JSON格式的配置数据
      # @param node [Object] 节点对象
      # @param outputs [Oxidized::Models::Outputs] 输出对象
      # @param opt [Hash] 选项哈希
      # @return [String] JSON格式的字符串
      def generate_json(node, outputs, opt)
        JSON.pretty_generate(
          'msg'    => opt[:msg],
          'user'   => opt[:user],
          'email'  => opt[:email],
          'group'  => opt[:group],
          'node'   => node,
          'config' => outputs.to_cfg
          # 实际上我们还需要遍历输出，用于其他类型如gitlab。
          # 但大多数人不使用'type'功能。
        )
      end
    end
  end
end
