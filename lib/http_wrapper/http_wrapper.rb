require 'net/https'

class HTTPWrapper
  KNOWN_OPTIONS_KEYS = [:timeout, :verify_cert, :logger, :max_redirects].freeze

  attr_accessor :timeout, :verify_cert, :logger, :max_redirects

  def initialize(options = {})
    unknown_options = options.keys - KNOWN_OPTIONS_KEYS

    if unknown_options.length > 0
      raise UnknownParameterError.new "Unknown options: #{unknown_options.join(', ')}"
    end

    @timeout       = options.fetch(:timeout) { 10 }
    @verify_cert   = options.fetch(:verify_cert) { true }
    @logger        = options.fetch(:logger) { nil }
    @max_redirects = options.fetch(:max_redirects) { 10 }
  end

  [:get, :post, :put, :delete].each do |method|
    define_method method do |url, params = {}|
      get_response Request.new(url, method, params)
    end

    %w(ajax json ajax_json).each do |header|
      define_method "#{method.to_s}_#{header}" do |url, params = {}|
        params[:headers] ||= {}
        params[:headers].merge! HTTPWrapper.const_get("#{header}_HEADER".upcase)
        __send__ method, url, params
      end
    end

    alias_method "#{method.to_s}_json_ajax", "#{method.to_s}_ajax_json"
  end

  def post_and_get_cookie(url, params = {})
    response = post url, params
    response.response['set-cookie']
  end

  private

  def get_response(request, redirects_limit = @max_redirects)
    raise TooManyRedirectsError.new 'Too many redirects!' if redirects_limit == 0

    response = perform_request request

    if response.kind_of? Net::HTTPRedirection
      request.uri = response['location']
      response = get_response request, redirects_limit - 1
    end

    response
  end

  def perform_request(request)
    connection = create_connection_for request.uri
    request.perform_using connection
  end

  def create_connection_for(uri)
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