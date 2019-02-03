# frozen_string_literal: true

class HTTPWrapper
  module Util
    def self.validate_hash_keys(hash_to_check, known_keys_array)
      unknown_keys = hash_to_check.keys - known_keys_array
      return if unknown_keys.empty?

      raise UnknownKeyError, "Unknown keys: #{unknown_keys.join(', ')}"
    end

    def self.query_to_hash(query)
      Hash[URI.decode_www_form query]
    end

    def self.hash_to_query(hash)
      URI.encode_www_form hash
    end
  end
end
