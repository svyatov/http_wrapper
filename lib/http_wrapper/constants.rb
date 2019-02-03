# frozen_string_literal: true

class HTTPWrapper
  USER_AGENT = "HTTPWrapper/#{HTTPWrapper::VERSION}; Ruby/#{RUBY_VERSION}"

  CONTENT_TYPE_HEADER_NAME = 'content-type'
  USER_AGENT_HEADER_NAME   = 'user-agent'
  COOKIE_HEADER_NAME       = 'cookie'
  AJAX_HEADER_NAME         = 'x-requested-with'

  DEFAULT_CONTENT_TYPE   = 'text/html; charset=UTF-8'
  JSON_CONTENT_TYPE      = 'application/json; charset=UTF-8'
  POST_CONTENT_TYPE      = 'application/x-www-form-urlencoded'
  MULTIPART_CONTENT_TYPE = 'multipart/form-data'

  AJAX_HEADER = { AJAX_HEADER_NAME => 'XMLHttpRequest' }.freeze
  JSON_HEADER = { CONTENT_TYPE_HEADER_NAME => JSON_CONTENT_TYPE }.freeze
  AJAX_JSON_HEADER = AJAX_HEADER.dup.merge!(JSON_HEADER).freeze
end
