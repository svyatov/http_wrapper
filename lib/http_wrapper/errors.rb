class HTTPWrapper
  HTTPWrapperError      = Class.new StandardError
  TooManyRedirectsError = Class.new HTTPWrapperError
  UnknownKeyError       = Class.new HTTPWrapperError
end