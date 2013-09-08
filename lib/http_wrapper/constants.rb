class HTTPWrapper
  KNOWN_OPTIONS_KEYS   = [:timeout, :ca_file, :validate_ssl_cert].freeze
  KNOWN_PARAMS_KEYS    = [:headers, :params, :cookie, :auth, :body, :method].freeze

  HEADER_CONTENT_TYPE  = 'Content-Type'.freeze

  DEFAULT_CONTENT_TYPE = 'text/xml; charset=UTF-8'.freeze
  JSON_CONTENT_TYPE    = 'application/json; charset=UTF-8'.freeze
  POST_CONTENT_TYPE    = 'application/x-www-form-urlencoded; charset=UTF-8'.freeze

  HEADER_USER_AGENT    = 'User-Agent'.freeze
  HEADER_COOKIE        = 'Cookie'.freeze

  HEADER_AJAX          = 'X-Requested-With'.freeze
  HEADER_AJAX_VALUE    = 'XMLHttpRequest'.freeze
end