require 'uri/common'

class HTTPWrapper
  KNOWN_PARAMS_KEYS = [:headers, :query, :cookie, :auth, :body].freeze

  class Request
    attr_accessor :headers

    def initialize(url, method, params = {})
      validate_parameters params

      self.url  = url
      @method   = method
      @headers  = params[:headers] || {}
      @query    = params[:query]   || {}
      @body     = params[:body]    || nil
      @cookie   = params[:cookie]  || @headers[HEADER::COOKIE] || nil
      @login    = params[:auth] && params[:auth].fetch(:login)
      @password = params[:auth] && params[:auth].fetch(:password)

      initialize_defaults
    end

    def url
      @uri
    end

    def url=(url)
      @uri = URI.parse url
    end

    def create
      build_uri
      create_http_request
      @request
    end

    private

    def validate_parameters(params)
      unknown_params = params.keys - KNOWN_PARAMS_KEYS

      if unknown_params.length > 0
        raise UnknownParameterError.new "Unknown parameters: #{unknown_params.join(', ')}"
      end
    end

    def initialize_defaults
      @headers[HEADER::USER_AGENT] ||= HTTPWrapper::USER_AGENT
      case @method
        when :post, :put, :delete then @headers[HEADER::CONTENT_TYPE] ||= CONTENT_TYPE::POST
        else @headers[HEADER::CONTENT_TYPE] ||= CONTENT_TYPE::DEFAULT
      end
    end

    def build_uri
      return unless @query.size > 0

      query = if @uri.query
                query_to_hash(@uri.query).merge(@query)
              else
                @query
              end

      @uri.query = URI.encode_www_form query
    end

    def create_http_request
      @request = Net::HTTP.const_get(@method.to_s.capitalize).new @uri.request_uri, @headers
      set_request_cookies
      set_request_body
      set_request_basic_auth
    end

    def set_request_body
      return unless @request.class::REQUEST_HAS_BODY && @body
      if @body.kind_of? Hash
        @request.set_form_data(@body)
      else
        @request.body = @body
      end
    end

    def set_request_basic_auth
      return unless @login
      @request.basic_auth @login, @password
    end

    def set_request_cookies
      return unless @cookie
      @request['Cookie'] = @cookie
    end

    def query_to_hash(query)
      Hash[URI.decode_www_form query]
    end
  end
end