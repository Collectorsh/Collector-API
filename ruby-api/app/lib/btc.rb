module Btc
  # Base58 is used for compact human-friendly representation of Bitcoin addresses and private keys.
  # Typically Base58-encoded text also contains a checksum (so-called "Base58Check").
  # Addresses look like 19FGfswVqxNubJbh1NW8A4t51T9x9RDVWQ.
  # Private keys look like 5KQntKuhYWSRXNqp2yhdXzjekYAR7US3MT1715Mbv5CyUKV6hVe.
  #
  # Here is what Satoshi said about Base58:
  # Why base-58 instead of standard base-64 encoding?
  # - Don't want 0OIl characters that look the same in some fonts and
  #      could be used to create visually identical looking account numbers.
  # - A string with non-alphanumeric characters is not as easily accepted as an account number.
  # - E-mail usually won't line-break if there's no punctuation to break at.
  # - Double-clicking selects the whole number as one word if it's all alphanumeric.
  #
  module Data
    extend self

    HEX_PACK_CODE = 'H*'.freeze
    BYTE_PACK_CODE = 'C*'.freeze

    # Generates a secure random number of a given length
    def random_data(length = 32)
      SecureRandom.random_bytes(length)
    end

    # Converts hexadecimal string to a binary data string.
    def data_from_hex(hex_string)
      raise ArgumentError, 'Hex string is missing' unless hex_string

      hex_string = hex_string.strip
      data = [hex_string].pack(HEX_PACK_CODE)
      if hex_from_data(data) != hex_string.downcase # invalid hex string was detected
        raise FormatError, "Hex string is invalid: #{hex_string.inspect}"
      end

      data
    end

    # Converts binary string to lowercase hexadecimal representation.
    def hex_from_data(data)
      raise ArgumentError, 'Data is missing' unless data

      data.unpack1(HEX_PACK_CODE)
    end

    def to_hex(data)
      hex_from_data(data)
    end

    def from_hex(hex)
      data_from_hex(hex)
    end

    # Converts a binary string to an array of bytes (list of integers).
    # Returns a much more efficient slice of bytes if offset/limit or
    # range are specified. That is, avoids converting the entire buffer to byte array.
    #
    # Note 1: if range is specified, it takes precedence over offset/limit.
    #
    # Note 2: byteslice(...).bytes is less efficient as it creates
    #         an intermediate shorter string.
    #
    def bytes_from_data(data, offset: 0, limit: nil, range: nil)
      raise ArgumentError, 'Data is missing' unless data
      return data.bytes if offset == 0 && limit.nil? && range.nil?

      if range
        offset = range.begin
        limit  = range.size
      end
      bytes = []
      data.each_byte do |byte|
        if offset > 0
          offset -= 1
        elsif !limit || limit > 0
          bytes << byte
          limit -= 1 if limit
        else
          break
        end
      end
      bytes
    end

    # Converts binary string to an array of bytes (list of integers).
    def data_from_bytes(bytes)
      raise ArgumentError, 'Bytes are missing' unless bytes

      bytes.pack(BYTE_PACK_CODE)
    end

    # Returns string as-is if it is ASCII-compatible
    # (that is, if you are interested in 7-bit characters exposed as #bytes).
    # If it is not, attempts to transcode to UTF8 replacing invalid characters if there are any.
    # If options are not specified, uses safe default that replaces unknown characters with standard character.
    # If options are specified, they are used as-is for String#encode method.
    def ensure_ascii_compatible_encoding(string, options = nil)
      if string.encoding.ascii_compatible?
        string
      else
        string.encode(Encoding::UTF_8, options || { invalid: :replace, undef: :replace })
      end
    end

    # Returns string as-is if it is already encoded in binary encoding (aka BINARY or ASCII-8BIT).
    # If it is not, converts to binary by calling stdlib's method #b.
    def ensure_binary_encoding(string)
      raise ArgumentError, 'String is missing' unless string

      if string.encoding == Encoding::BINARY
        string
      else
        string.b
      end
    end
  end

  module Base58
    extend self

    ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'.freeze

    # Converts binary string into its Base58 representation.
    # If string is empty returns an empty string.
    # If string is nil raises ArgumentError
    def base58_from_data(data)
      raise ArgumentError, 'Data is missing' unless data

      leading_zeroes = 0
      int = 0
      base = 1
      data.bytes.reverse_each do |byte|
        if byte == 0
          leading_zeroes += 1
        else
          leading_zeroes = 0
          int += base * byte
        end
        base *= 256
      end
      ('1' * leading_zeroes) + base58_from_int(int)
    end

    # Converts binary string into its Base58 representation.
    # If string is empty returns an empty string.
    # If string is nil raises ArgumentError.
    def data_from_base58(string)
      raise ArgumentError, 'String is missing' unless string

      int = int_from_base58(string)
      bytes = []
      while int > 0
        remainder = int % 256
        int /= 256
        bytes.unshift(remainder)
      end
      data = Btc::Data.data_from_bytes(bytes)
      byte_for_1 = '1'.bytes.first
      Btc::Data.ensure_ascii_compatible_encoding(string).bytes.each do |byte|
        break if byte != byte_for_1

        data = "\x00" + data
      end
      data
    end

    def base58check_from_data(data)
      raise ArgumentError, 'Data is missing' unless data

      base58_from_data(data + Btc.hash256(data)[0, 4])
    end

    def data_from_base58check(string)
      data = data_from_base58(string)
      raise FormatError, "Invalid Base58Check string: too short string #{string.inspect}" if data.bytesize < 4

      payload_size = data.bytesize - 4
      payload = data[0, payload_size]
      checksum = data[payload_size, 4]
      if checksum != Btc.hash256(payload)[0, 4]
        raise FormatError, "Invalid Base58Check string: checksum invalid in #{string.inspect}"
      end

      payload
    end

    private

    def base58_from_int(int)
      raise ArgumentError, 'Integer is missing' unless int

      string = ''
      base = ALPHABET.size
      while int > 0
        int, remainder = int.divmod(base)
        string = ALPHABET[remainder] + string
      end
      string
    end

    def int_from_base58(string)
      raise ArgumentError, 'String is missing' unless string

      int = 0
      base = ALPHABET.size
      string.reverse.each_char.with_index do |char, index|
        char_index = ALPHABET.index(char)
        unless char_index
          raise FormatError,
                "Invalid Base58 character: #{char.inspect} at index #{index} (full string: #{string.inspect})"
        end

        int += char_index * (base**index)
      end
      int
    end
  end
end
