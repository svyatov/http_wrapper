# frozen_string_literal: true

require 'uri/common'

class HTTPWrapper
  class Request
    def initialize(url, method, headers: nil, query: nil, cookie: nil, auth: nil,
                   body: nil, user_agent: nil, content_type: nil, multipart: nil)
      self.uri = url

      @query   = query || {}
      @headers = normalize_headers(headers)
      @method  = HTTP_METHODS.fetch(method)
      @cookie  = cookie

      @body_data      = body
      @multipart_data = multipart
      @user_agent     = user_agent
      @content_type   = content_type || default_content_type_for(method)

      if auth
        @login    = auth.fetch(:login)
        @password = auth.fetch(:password)
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
        normal_headers[normalize_header(header)] = value
      end
      normal_headers
    end

    def normalize_header(header)
      header = header.to_s.tr('_', '-') if header.is_a? Symbol
      header.downcase
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

      original_query = @uri.query ? URI.decode_www_form(@uri.query).to_h : {}
      merged_query = original_query.merge @query
      @uri.query = URI.encode_www_form(merged_query)
    end

    def create_method_specific_request
      @request = @method.new @uri, @headers
      apply_body
      apply_basic_auth
      @request
    end

    def apply_body
      return unless @request.request_body_permitted?

      if @multipart_data
        apply_multipart_body
      else
        apply_regular_body
      end
    end

    def apply_multipart_body
      merge_body_into_multipart if @body_data
      @request.set_form @multipart_data, MULTIPART_CONTENT_TYPE
    end

    def merge_body_into_multipart
      @body_data = URI.decode_www_form(@body_data).to_h unless @body_data.is_a? Hash
      @body_data.each { |key, value| @multipart_data << [key.to_s, value.to_s] }
    end

    def apply_regular_body
      return unless @body_data

      @request.body = @body_data.is_a?(Hash) ? URI.encode_www_form(@body_data) : @body_data
    end

    def apply_basic_auth
      return unless @login && @password

      @request.basic_auth @login, @password
    end
  end
end
