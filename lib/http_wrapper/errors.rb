# frozen_string_literal: true

class HTTPWrapper
  class Error < StandardError
  end

  class TooManyRedirectsError < Error
  end

  class UnknownKeyError < Error
  end
end
