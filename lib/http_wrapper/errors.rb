# frozen_string_literal: true

class HTTPWrapper
  class Error < StandardError
  end

  class TooManyRedirectsError < Error
  end
end
