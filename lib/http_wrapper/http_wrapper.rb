require 'net/https'

class HTTPWrapper
  KNOWN_OPTIONS_KEYS = [:timeout, :ca_file, :validate_ssl_cert].freeze

  attr_accessor :timeout, :ca_file, :validate_ssl_cert

  def initialize(options = {})
    unknown_options = options.keys - KNOWN_OPTIONS_KEYS

    if unknown_options.length > 0
      raise UnknownParameterError.new "Unknown options: #{unknown_options.join(', ')}"
    end

    @timeout           = options.fetch(:timeout) { 10 }
    @ca_file           = options.fetch(:ca_file) { nil }
    @validate_ssl_cert = options.fetch(:validate_ssl_cert) { false }
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

  def get_response(request, redirects_limit = 10)
    raise TooManyRedirectsError.new 'Too many redirects!' if redirects_limit == 0

    response = perform_request request

    if response.kind_of? Net::HTTPRedirection
      request.url = response['location']
      response = get_response request, redirects_limit - 1
    end

    response
  end

  def perform_request(request)
    connection = create_connection request.url
    connection.request request.create
  end

  def create_connection(uri)
    connection = Net::HTTP.new uri.host, uri.port
    connection.read_timeout = timeout
    connection.open_timeout = timeout

    if uri.scheme == 'https'
      connection.use_ssl = true

      if validate_ssl_cert
        connection.ca_file = ca_file
        connection.verify_mode = OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
      else
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end

    connection
  end
end