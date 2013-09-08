require 'uri/common'
require 'net/https'
require_relative 'constants'
require_relative 'errors'
require_relative 'version'

class HTTPWrapper
  attr_accessor :timeout, :ca_file, :validate_ssl_cert

  def initialize(options = {})
    unknown_options = options.keys - KNOWN_OPTIONS_KEYS

    if unknown_options.length > 0
      raise UnknownParameterError.new "Unknown options: #{unknown_options.join(', ')}"
    end

    @timeout           = options.fetch(:timeout) { 10000 }
    @ca_file           = options.fetch(:ca_file) { nil }
    @validate_ssl_cert = options.fetch(:validate_ssl_cert) { false }
  end

  def self.default_user_agent
    "HTTPWrapper/#{VERSION}; Ruby/#{RUBY_VERSION}"
  end

  def get(url, params = {})
    params = validate_parameters_and_init_headers params
    locate_response url, params
  end

  [:post, :put, :delete].each do |method|
    define_method method do |url, params = {}|
      params = validate_parameters_and_init_headers params
      params[:headers][HEADER_CONTENT_TYPE] ||= POST_CONTENT_TYPE
      params[:method] = method
      locate_response url, params
    end
  end

  def get_soap(url, params = {})
    params = validate_parameters_and_init_headers params
    params[:headers]['SOAPAction'] ||= ''
    params[:headers][HEADER_CONTENT_TYPE] ||= DEFAULT_CONTENT_TYPE
    locate_response url, params
  end

  [:post, :put, :delete].each do |method|
    define_method "#{method.to_s}_soap" do |url, params = {}|
      params[:method] = method
      get_soap url, params
    end
  end

  def get_ajax(url, params = {})
    params = validate_parameters_and_init_headers params
    params[:headers][HEADER_AJAX] = HEADER_AJAX_VALUE
    locate_response url, params
  end

  [:post, :put, :delete].each do |method|
    define_method "#{method.to_s}_ajax" do |url, params = {}|
      params[:method] = method
      get_ajax url, params
    end
  end

  def get_json(url, params = {})
    params = validate_parameters_and_init_headers params
    params[:headers][HEADER_CONTENT_TYPE] = JSON_CONTENT_TYPE
    locate_response url, params
  end

  [:post, :put, :delete].each do |method|
    define_method "#{method.to_s}_json" do |url, params = {}|
      params[:method] = method
      get_json url, params
    end
  end

  def get_ajax_json(url, params = {})
    params = validate_parameters_and_init_headers params
    params[:headers][HEADER_CONTENT_TYPE] = JSON_CONTENT_TYPE
    get_ajax url, params
  end

  [:post, :put, :delete].each do |method|
    define_method "#{method.to_s}_ajax_json" do |url, params = {}|
      params[:method] = method
      get_ajax_json url, params
    end
  end

  %w(get post put delete).each do |method|
    alias_method "#{method}_json_ajax", "#{method}_ajax_json"
  end

  def post_and_get_cookie(url, params = {})
    response = post url, params
    response.response['set-cookie']
  end

  private

  def validate_parameters_and_init_headers(params)
    params[:headers] ||= {}
    unknown_params = params.keys - KNOWN_PARAMS_KEYS

    if unknown_params.length > 0
      raise UnknownParameterError.new "Unknown parameters: #{unknown_params.join(', ')}"
    end

    params
  end

  def locate_response(url, params, redirects_limit = 10)
    raise TooManyRedirectsError.new 'Too many redirects!' if redirects_limit == 0

    response = execute_request url, params

    if response.kind_of? Net::HTTPRedirection
      response = locate_response response['location'], params, redirects_limit - 1
    end

    response
  end

  def execute_request(url, params)
    params[:headers] ||= {}
    params[:headers][HEADER_USER_AGENT]   ||= self.class.default_user_agent
    params[:headers][HEADER_CONTENT_TYPE] ||= DEFAULT_CONTENT_TYPE
    params[:headers][HEADER_COOKIE] = params[:cookie] if params[:cookie]

    uri = build_uri url, params[:params]
    connection = create_connection uri
    request = create_request uri, params

    Timeout.timeout(timeout) do
      connection.request(request)
    end
  end

  def build_uri(url, query_params)
    uri = URI url

    if query_params
      if uri.query && !uri.query.empty?
        new_query = Hash[URI.decode_www_form(uri.query)].merge(query_params)
      else
        new_query = query_params
      end
      uri.query = URI.encode_www_form new_query
    end

    uri
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

  def create_request(uri, params)
    case params[:method]
      when :get
        request = Net::HTTP::Get.new    uri.request_uri, params[:headers]
      when :post
        request = Net::HTTP::Post.new   uri.request_uri, params[:headers]
      when :put
        request = Net::HTTP::Put.new    uri.request_uri, params[:headers]
      when :delete
        request = Net::HTTP::Delete.new uri.request_uri, params[:headers]
      else
        request = Net::HTTP::Get.new    uri.request_uri, params[:headers]
    end

    if [:post, :put, :delete].include? params[:method]
      request.body = params[:body] if params[:body].kind_of? String
      request.set_form_data(params[:body]) if params[:body].kind_of? Hash
    end

    if params[:auth]
      request.basic_auth params[:auth].fetch(:login), params[:auth].fetch(:password)
    end

    request
  end
end