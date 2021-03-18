module AttrVault
  class Key
    attr_reader :id, :value

    def initialize(id, value)
      if value.nil? || value.empty?
        raise InvalidKey, "key value required"
      end
      begin
        id = Integer(id)
      rescue
        raise InvalidKey, "key id must be an integer"
      end

      @id = id
      @value = value
    end

    def digest(data)
      AttrVault::Encryption::hmac_digest(value, data)
    end

    def to_json(*args)
      { id: id, value: value }.to_json
    end
  end

  class Keyring
    attr_reader :keys, :use_nth_newest_key

    def self.load(keyring_data, use_nth_newest_key = 1)
      keyring = Keyring.new(use_nth_newest_key)
      begin
        candidate_keys = JSON.parse(keyring_data, symbolize_names: true)

        if candidate_keys.is_a?(Hash)
          candidate_keys.each do |key_id, key|
            keyring.add_key(Key.new(key_id.to_s, key))
          end
        else
          raise InvalidKeyring, "Invalid JSON structure"
        end
      rescue StandardError => e
        raise InvalidKeyring, e.message
      end
      keyring
    end

    def initialize(use_nth_newest_key = 1)
      @keys = []
	  @use_nth_newest_key = use_nth_newest_key
    end

    def add_key(k)
      @keys << k
    end

    def drop_key(id_or_key)
      id = if id_or_key.is_a? Key
             id_or_key.id
           else
             id_or_key
           end
      @keys.reject! { |k| k.id == id }
    end

    def fetch(id)
      @keys.find { |k| k.id == id } or raise UnknownKey, id
    end

    def has_key?(id)
      !@keys.find { |k| k.id == id }.nil?
    end

    def current_key
      k = @keys.max_by(@use_nth_newest_key, &:id).last
      if k.nil?
        raise KeyringEmpty, "No keys in keyring"
      end
      k
    end

    def digests(data)
      keys.map { |k| k.digest(data) }
    end

    def to_json
      @keys.each_with_object({}) do |k,obj|
        obj[k.id] = k.value
      end.to_json
    end
  end
end
