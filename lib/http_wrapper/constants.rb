class HTTPWrapper
  module HEADER
    CONTENT_TYPE = 'content-type'.freeze
    USER_AGENT   = 'user-agent'.freeze
    COOKIE       = 'cookie'.freeze
    AJAX         = 'x-requested-with'.freeze
  end

  module CONTENT_TYPE
    DEFAULT   = 'text/html; charset=UTF-8'.freeze
    JSON      = 'application/json; charset=UTF-8'.freeze
    POST      = 'application/x-www-form-urlencoded'.freeze
    MULTIPART = 'multipart/form-data'.freeze
  end

  USER_AGENT  = "HTTPWrapper/#{HTTPWrapper::VERSION}; Ruby/#{RUBY_VERSION}".freeze
  AJAX_HEADER = { HEADER::AJAX => 'XMLHttpRequest'.freeze }.freeze
  JSON_HEADER = { HEADER::CONTENT_TYPE => CONTENT_TYPE::JSON }.freeze
  AJAX_JSON_HEADER = AJAX_HEADER.dup.merge!(JSON_HEADER).freeze
end