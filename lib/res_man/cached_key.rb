# require 'etcd'

module ResMan

  # This class provides a cache around backing store keys.
  class CachedKey

    def initialize(store, key, time_to_live, initial_value = nil)
      @store = store
      @last_checked = nil
      @key = key
      @ttl = time_to_live

      return if initial_value.nil?
      self.value = initial_value unless store.exists?(@key)
    end

    def value
      if expired?
        begin
          @value = @store.get(@key).value
          @last_checked = Time.now.to_f
        rescue Etcd::KeyNotFound # todo - this will need to change if we decide to generalize what backing stores can be used
          return nil
        end
      end

      @value
    end

    def value=(new_value)
      @store.safe_update(@key, new_value, value)
      @value = new_value
      @last_checked = Time.now.to_f
    end

    def invalidate
      @last_checked = nil
    end

    def expired?
      @last_checked.nil? || (Time.now.to_f - @last_checked > @ttl)
    end

  end
end
