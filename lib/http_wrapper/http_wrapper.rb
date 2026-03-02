# frozen_string_literal: true

require 'net/https'

class HTTPWrapper
  HTTP_METHODS = {
    get: Net::HTTP::Get,
    post: Net::HTTP::Post,
    put: Net::HTTP::Put,
    delete: Net::HTTP::Delete
  }.freeze

  REQUEST_TYPES = %w[ajax json ajax_json].freeze

  attr_accessor :timeout, :verify_cert, :logger, :max_redirects, :user_agent

  def initialize(timeout: 10, verify_cert: true, logger: nil, max_redirects: 10, user_agent: USER_AGENT)
    @timeout       = timeout
    @verify_cert   = verify_cert
    @logger        = logger
    @max_redirects = max_redirects
    @user_agent    = user_agent
  end

  %i[get post put delete].each do |method_as_symbol|
    define_method method_as_symbol do |url, headers: nil, query: nil, cookie: nil,
                                          auth: nil, body: nil, user_agent: nil,
                                          content_type: nil, multipart: nil|
      user_agent ||= @user_agent
      request = Request.new(url, method_as_symbol,
                            headers:, query:, cookie:, auth:, body:,
                            user_agent:, content_type:, multipart:)
      perform_request(request)
    end

    method_as_string = method_as_symbol.to_s

    REQUEST_TYPES.each do |request_type|
      type_headers = HEADERS_FOR_REQUEST_TYPE.fetch(request_type)
      define_method "#{method_as_string}_#{request_type}" do |url, **params|
        params[:headers] = (params[:headers] || {}).merge(type_headers)
        public_send(method_as_symbol, url, **params)
      end
    end

    alias_method "#{method_as_string}_json_ajax", "#{method_as_string}_ajax_json"
  end

  def post_and_get_cookie(url, **params)
    response = post(url, **params)
    response['set-cookie']
  end

  def execute(request, uri)
    connection = create_connection uri
    connection.request request
  end

  private

  def perform_request(request, redirects_limit = @max_redirects)
    raise TooManyRedirectsError, 'Too many redirects!' if redirects_limit == 0

    response = execute request.create, request.uri

    if response.is_a? Net::HTTPRedirection
      request.uri = response['location']
      response = perform_request request, redirects_limit - 1
    end

    response
  end

  def create_connection(uri)
    connection = Net::HTTP.new uri.host, uri.port
    connection.read_timeout  = @timeout
    connection.open_timeout  = @timeout
    connection.write_timeout = @timeout

    if uri.is_a? URI::HTTPS
      connection.use_ssl = true
      connection.verify_mode = OpenSSL::SSL::VERIFY_NONE unless @verify_cert
    end

    connection.set_debug_output(@logger)
    connection
  end
end
