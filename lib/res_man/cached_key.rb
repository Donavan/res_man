require 'etcd'

module ResMan
  # This class provides a cache around etcd keys.
  class CachedKey
    def initialize(client, key, ttl, initial_value = nil)
      @client = client
      @last_checked = 0
      @key = key
      @ttl = ttl
      @value = nil
      return if initial_value.nil?
      self.value = initial_value unless @client.exists?(@key)
    end

    def value
      if @value.nil? || expired?
        begin
          @value = @client.get(@key).value
          @last_checked = Time.now.to_f
        rescue Etcd::KeyNotFound
          return nil
        end
      end
      @value
    end

    def value=(val)
      @client.safe_update(@key, val, value)
      @value = val
      @last_checked = Time.now.to_f
    end

    def invalidate
      @last_checked = nil
    end

    private

    def expired?
      @last_checked.nil? || (Time.now.to_f - @last_checked > @ttl)
    end
  end
end
