class HTTPWrapper
  module HEADERS
    CONTENT_TYPE = 'Content-Type'.freeze
    USER_AGENT   = 'User-Agent'.freeze
    COOKIE       = 'Cookie'.freeze
    AJAX         = 'X-Requested-With'.freeze

    DEFAULT_USER_AGENT  = "HTTPWrapper/#{HTTPWrapper::VERSION}; Ruby/#{RUBY_VERSION}".freeze
    DEFAULT_AJAX_HEADER = 'XMLHttpRequest'.freeze
  end

  module CONTENT_TYPES
    DEFAULT = 'text/xml; charset=UTF-8'.freeze
    JSON    = 'application/json; charset=UTF-8'.freeze
    POST    = 'application/x-www-form-urlencoded; charset=UTF-8'.freeze
  end
end