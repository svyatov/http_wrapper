# frozen_string_literal: true

require 'uri/common'

class HTTPWrapper
  class Request
    KNOWN_PARAMS_KEYS = %i[headers query cookie auth body user_agent content_type multipart].freeze

    def initialize(url, method, params = {}) # rubocop:disable Metrics/AbcSize
      Util.validate_hash_keys params, KNOWN_PARAMS_KEYS

      self.uri = url

      @query   = params[:query] || {}
      @headers = normalize_headers params[:headers]
      @method  = http_method_class_for method
      @cookie  = params[:cookie]

      @body_data      = params[:body]
      @multipart_data = params[:multipart]
      @user_agent     = params[:user_agent]
      @content_type   = params[:content_type] || default_content_type_for(method)

      if params[:auth]
        @login    = params[:auth].fetch(:login)
        @password = params[:auth].fetch(:password)
      end

      initialize_headers
    end

    attr_reader :uri

    def uri=(url)
      url = "http://#{url}" unless %r{\Ahttps?://}.match?(url)
      @uri = URI.parse url
    end

    def create
      merge_uri_query
      create_method_specific_request
    end

    private

    def normalize_headers(headers)
      normal_headers = {}
      headers&.each do |header, value|
        normal_headers[normalize_header header] = value
      end
      normal_headers
    end

    def normalize_header(header)
      header = header.to_s.tr('_', '-') if header.is_a? Symbol
      header.downcase
    end

    def http_method_class_for(method)
      Net::HTTP.const_get method.to_s.capitalize
    end

    def default_content_type_for(method)
      case method
      when :post, :put then POST_CONTENT_TYPE
      else DEFAULT_CONTENT_TYPE
      end
    end

    def initialize_headers
      @headers[USER_AGENT_HEADER_NAME]   ||= @user_agent
      @headers[CONTENT_TYPE_HEADER_NAME] ||= @content_type
      @headers[COOKIE_HEADER_NAME]       ||= @cookie if @cookie
    end

    def merge_uri_query
      return if @query.empty?

      original_query = @uri.query ? Util.query_to_hash(@uri.query) : {}
      merged_query = original_query.merge @query
      @uri.query = Util.hash_to_query merged_query
    end

    def create_method_specific_request
      @request = @method.new @uri, @headers
      set_body
      set_basic_auth
      @request
    end

    def set_body
      return unless @request.request_body_permitted?

      if @multipart_data
        set_body_from_multipart_data
      else
        set_body_from_body_data
      end
    end

    def set_body_from_multipart_data
      convert_body_data_to_multipart_data if @body_data
      @request.set_form @multipart_data, MULTIPART_CONTENT_TYPE
    end

    def convert_body_data_to_multipart_data
      @body_data = Util.query_to_hash(@body_data) unless @body_data.is_a? Hash
      @body_data.each { |key, value| @multipart_data << [key.to_s, value.to_s] }
    end

    def set_body_from_body_data
      return unless @body_data

      @request.body = @body_data.is_a?(Hash) ? Util.hash_to_query(@body_data) : @body_data
    end

    def set_basic_auth
      return unless @login && @password

      @request.basic_auth @login, @password
    end
  end
end
