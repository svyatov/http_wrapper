class HTTPWrapper
  module Utils
    def self.validate_hash_keys(hash_to_check, known_keys_array)
      unknown_keys = hash_to_check.keys - known_keys_array
      if unknown_keys.length > 0
        raise UnknownKeyError.new "Unknown keys: #{unknown_keys.join(', ')}"
      end
    end
  end
end