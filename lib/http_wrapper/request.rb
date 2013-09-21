require 'uri/common'

class HTTPWrapper
  class Request
    KNOWN_PARAMS_KEYS = [:headers, :query, :cookie, :auth, :body, :user_agent, :content_type, :multipart].freeze

    def initialize(url, method, params = {})
      Utils.validate_hash_keys params, KNOWN_PARAMS_KEYS

      self.uri  = url

      @headers  = params[:headers] || {}
      @query    = params[:query]   || {}
      @login    = params[:auth] && params[:auth].fetch(:login)
      @password = params[:auth] && params[:auth].fetch(:password)

      @method   = Net::HTTP.const_get(method.to_s.capitalize)

      @body         = params[:body]
      @cookie       = params[:cookie]
      @user_agent   = params[:user_agent]
      @content_type = params[:content_type] || default_content_type_for(method)

      @multipart_data = params[:multipart]

      initialize_headers
    end

    attr_reader :uri

    def uri=(url)
      url = "http://#{url}" unless url =~ /\Ahttps?:\/\//
      @uri = URI.parse url
    end

    def create
      rebuild_uri_query_params
      convert_symbol_headers_to_string
      create_http_request
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

    def rebuild_uri_query_params
      return unless @query.size > 0
      query = @uri.query ? Utils.query_to_hash(@uri.query).merge(@query) : @query
      @uri.query = Utils.hash_to_query query
    end

    def convert_symbol_headers_to_string
      @headers.keys.select{|key| key.is_a? Symbol}.each do |key|
        str_key = key.to_s.gsub(/_/, '-').capitalize
        @headers[str_key] = @headers.delete key
      end
    end

    def create_http_request
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
      convert_body_data_to_multipart_data if @body
      @request.set_form @multipart_data, CONTENT_TYPE::MULTIPART
    end

    def convert_body_data_to_multipart_data
      @body = Utils.query_to_hash(@body) unless @body.kind_of? Hash
      @body.each{|key, value| @multipart_data << [key.to_s, value.to_s]}
    end

    def set_body_from_body_data
      return unless @body
      @request.body = @body.is_a?(Hash) ? Utils.hash_to_query(@body) : @body
    end

    def set_basic_auth
      return unless @login
      @request.basic_auth @login, @password
    end
  end
end