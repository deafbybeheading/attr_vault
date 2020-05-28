# frozen_string_literal: true
require 'base64'

module AttrVault
  # borrowed wholesale from Fernet, enhanced for use with AEAD cipher
  # suites.

  # Internal: Encapsulates a secret key, a 32-byte sequence consisting
  #   of an encryption and a signing key.
  class Secret
    attr_reader :aead

    # Internal - Initialize a Secret
    #
    # secret - the secret, optionally encoded with either standard or
    #          URL safe variants of Base64 encoding
    #
    # Raises AttrVault::Secret::InvalidSecret if it cannot be decoded or is
    #   not of the expected length
    def initialize(secret, aead:)
      @aead = aead

      if secret.bytesize == 32
        @secret = secret
      else
        begin
          @secret = Base64.urlsafe_decode64(secret)
        rescue ArgumentError
          @secret = Base64.decode64(secret)
        end
        unless @secret.bytesize == 32
          raise InvalidSecret,
            "Secret must be 32 bytes, instead got #{@secret.bytesize}"
        end
      end
    end

    # Internal: Returns the portion of the secret token used for encryption
    def encryption_key
      if @aead
        @secret
      else
        @secret.slice(16, 16)
      end
    end

    # Internal: Returns the portion of the secret token used for signing
    def signing_key
      if @aead
        raise Error.new('signing_key must not be used for AEAD ciphers')
      end

      @secret.slice(0, 16)
    end

    # Public: String representation of this secret, masks to avoid leaks.
    def to_s
      "<AttrVault::Secret [masked]>"
    end
    alias to_s inspect
  end
end
