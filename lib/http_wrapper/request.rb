require 'uri/common'

class HTTPWrapper
  class Request
    KNOWN_PARAMS_KEYS = [:headers, :query, :cookie, :auth, :body, :user_agent, :content_type, :multipart].freeze

    def initialize(url, method, params = {})
      Utils.validate_hash_keys params, KNOWN_PARAMS_KEYS

      self.uri = url

      @query   = params[:query] || {}
      @headers = normalize_headers params[:headers]
      @method  = Net::HTTP.const_get method.to_s.capitalize
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
      url = "http://#{url}" unless url =~ /\Ahttps?:\/\//
      @uri = URI.parse url
    end

    def create
      merge_uri_query
      create_method_specific_request
    end

    private

    def initialize_headers
      @headers[HEADER::USER_AGENT]   ||= @user_agent
      @headers[HEADER::CONTENT_TYPE] ||= @content_type
      @headers[HEADER::COOKIE]       ||= @cookie if @cookie
    end

    def default_content_type_for(method)
      case method
        when :post, :put then CONTENT_TYPE::POST
        else CONTENT_TYPE::DEFAULT
      end
    end

    def merge_uri_query
      return unless @query.size > 0
      original_query = @uri.query ? Utils.query_to_hash(@uri.query) : {}
      merged_query = original_query.merge @query
      @uri.query = Utils.hash_to_query merged_query
    end

    def normalize_headers(headers)
      normal_headers = {}
      if headers
        headers.each do |header, value|
          normal_headers[normalize_header header] = value
        end
      end
      normal_headers
    end

    def normalize_header(header)
      header = header.to_s.gsub(/_/, '-') if header.is_a? Symbol
      header.downcase
    end

    def create_method_specific_request
      # Ruby v1.9.3 doesn't understand full URI object, it needs just path :(
      uri = RUBY_VERSION =~ /\A2/ ? @uri : @uri.request_uri
      @request = @method.new uri, @headers
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
      @request.set_form @multipart_data, CONTENT_TYPE::MULTIPART
    end

    def convert_body_data_to_multipart_data
      @body_data = Utils.query_to_hash(@body_data) unless @body_data.kind_of? Hash
      @body_data.each{|key, value| @multipart_data << [key.to_s, value.to_s]}
    end

    def set_body_from_body_data
      return unless @body_data
      @request.body = @body_data.is_a?(Hash) ? Utils.hash_to_query(@body_data) : @body_data
    end

    def set_basic_auth
      return unless @login
      @request.basic_auth @login, @password
    end
  end
end