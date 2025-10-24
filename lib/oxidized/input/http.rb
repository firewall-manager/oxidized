module Oxidized
  require "oxidized/input/cli"
  require "net/http"
  require "json"
  require "net/http/digest_auth"

  # HTTP输入模块
  # 通过HTTP/HTTPS协议从设备获取配置
  # 支持基本认证、摘要认证和基于表单的认证
  class HTTP < Input
    include Input::CLI  # 包含CLI通用功能

    # 连接到HTTP服务器
    # @param node [Node] 要连接的节点对象
    # @return [Boolean] 连接是否成功
    def connect(node)
      @node = node
      @secure = false      # 是否使用HTTPS
      @username = nil      # 认证用户名
      @password = nil      # 认证密码
      @headers = {}        # HTTP请求头
      # 如果启用调试模式，创建日志文件记录HTTP操作
      @log = File.open(Oxidized::Config::LOG + "/#{@node.ip}-http", "w") if Oxidized.config.input.debug?
      # 执行模型中定义的HTTP配置回调
      @node.model.cfg["http"].each { |cb| instance_exec(&cb) }

      # 如果没有主页面或未定义登录方法，直接返回成功
      return true unless @main_page && defined?(login)

      begin
        require "mechanize"  # 用于处理复杂的Web认证
      rescue LoadError
        raise OxidizedError, "mechanize not found: sudo gem install mechanize"
      end

      # 使用Mechanize进行Web认证
      @m = Mechanize.new
      url = URI::HTTP.build host: @node.ip, path: @main_page
      @m_page = @m.get(url.to_s)
      login
    end

    # 执行HTTP命令
    # @param callback_or_string [Proc, String] 回调函数或命令字符串
    # @return [String] 响应内容
    def cmd(callback_or_string)
      return cmd_cb callback_or_string if callback_or_string.is_a?(Proc)

      cmd_str callback_or_string
    end

    # 执行回调函数
    # @param callback [Proc] 要执行的回调函数
    # @return [String] 回调函数返回值
    def cmd_cb(callback)
      instance_exec(&callback)
    end

    # 执行字符串命令（HTTP请求）
    # @param string [String] 包含密码占位符的路径字符串
    # @return [String] HTTP响应内容
    def cmd_str(string)
      path = string % { password: @node.auth[:password] }
      get_http path
    end

    private

    # 执行HTTP请求并处理认证
    # @param path [String] 请求路径
    # @return [String] 响应内容
    def get_http(path)
      uri = get_uri(path)

      logger.debug "Making request to: #{uri}"

      # 根据配置决定是否验证SSL证书
      ssl_verify = Oxidized.config.input.http.ssl_verify? ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE

      # 发送初始请求
      res = make_request(uri, ssl_verify)

      # 如果服务器返回401且要求摘要认证
      if res.code == '401' && res['www-authenticate']&.include?('Digest')
        uri.user = @username
        uri.password = URI.encode_www_form_component(@password)
        logger.debug "Server requires Digest authentication"
        # 生成摘要认证头
        auth = Net::HTTP::DigestAuth.new.auth_header(uri, res['www-authenticate'], 'GET')

        res = make_request(uri, ssl_verify, 'Authorization' => auth)
      elsif @username && @password
        # 回退到基本认证
        logger.debug "Falling back to Basic authentication"
        res = make_request(uri, ssl_verify, 'Authorization' => basic_auth_header)
      end

      logger.debug "Response code: #{res.code}"
      res.body
    end

    # 发送HTTP请求
    # @param uri [URI] 请求URI
    # @param ssl_verify [Integer] SSL验证模式
    # @param extra_headers [Hash] 额外的请求头
    # @return [Net::HTTPResponse] HTTP响应对象
    def make_request(uri, ssl_verify, extra_headers = {})
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", verify_mode: ssl_verify) do |http|
        req = Net::HTTP::Get.new(uri)
        # 添加所有请求头
        @headers.merge(extra_headers).each { |header, value| req.add_field(header, value) }
        logger.debug "Sending request with headers: #{@headers.merge(extra_headers)}"
        http.request(req)
      end
    end

    # 生成基本认证头
    # @return [String] Base64编码的认证头
    def basic_auth_header
      "Basic " + ["#{@username}:#{@password}"].pack('m').delete("\r\n")
    end

    # 记录日志
    # @param str [String] 要记录的字符串
    def log(str)
      @log&.write(str)
    end

    # 断开HTTP连接
    def disconnect
      @log.close if Oxidized.config.input.debug?
    end

    # 构建URI对象
    # @param path [String] 路径字符串
    # @return [URI] 构建的URI对象
    def get_uri(path)
      path = URI.parse(path)
      # 根据安全设置选择HTTP或HTTPS
      uri_class = @secure ? URI::HTTPS : URI::HTTP
      uri_class.build(host:  @node.ip,
                      path:  path.path,
                      query: path.query)
    end
  end
end
