# frozen_string_literal: true

class HTTPWrapper
  Error = Class.new StandardError
  TooManyRedirectsError = Class.new Error
  UnknownKeyError = Class.new Error
end
