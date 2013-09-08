class HTTPWrapper
  HTTPWrapperError      = Class.new StandardError
  TooManyRedirectsError = Class.new HTTPWrapperError
  UnknownParameterError = Class.new HTTPWrapperError
end