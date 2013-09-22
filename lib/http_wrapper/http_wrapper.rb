require 'net/https'

class HTTPWrapper
  KNOWN_OPTIONS_KEYS = [:timeout, :verify_cert, :logger, :max_redirects, :user_agent].freeze

  attr_accessor :timeout, :verify_cert, :logger, :max_redirects, :user_agent

  def initialize(options = {})
    Utils.validate_hash_keys options, KNOWN_OPTIONS_KEYS

    @timeout       = options.fetch(:timeout) { 10 }
    @verify_cert   = options.fetch(:verify_cert) { true }
    @logger        = options.fetch(:logger) { nil }
    @max_redirects = options.fetch(:max_redirects) { 10 }
    @user_agent    = options.fetch(:user_agent) { USER_AGENT }
  end

  [:get, :post, :put, :delete].each do |method|
    define_method method do |url, params = {}|
      params[:user_agent] ||= @user_agent
      get_response Request.new(url, method, params)
    end

    %w(ajax json ajax_json).each do |header|
      define_method "#{method.to_s}_#{header}" do |url, params = {}|
        params[:headers] ||= {}
        params[:headers].merge! HTTPWrapper.const_get("#{header}_HEADER".upcase)
        public_send method, url, params
      end
    end

    alias_method "#{method.to_s}_json_ajax", "#{method.to_s}_ajax_json"
  end

  def post_and_get_cookie(url, params = {})
    response = post url, params
    response['set-cookie']
  end

  def execute(request, uri)
    connection = create_connection uri
    connection.request request
  end

  private

  def get_response(request, redirects_limit = @max_redirects)
    raise TooManyRedirectsError.new 'Too many redirects!' if redirects_limit == 0

    response = execute request.create, request.uri

    if response.kind_of? Net::HTTPRedirection
      request.uri = response['location']
      response = get_response request, redirects_limit - 1
    end

    response
  end

  def create_connection(uri)
    connection = Net::HTTP.new uri.host, uri.port
    connection.read_timeout = @timeout
    connection.open_timeout = @timeout

    if uri.kind_of? URI::HTTPS
      connection.use_ssl = true
      connection.verify_mode = OpenSSL::SSL::VERIFY_NONE unless @verify_cert
    end

    connection.set_debug_output(@logger)
    connection
  end
end