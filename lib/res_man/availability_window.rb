module ResMan
  # Represents a window of time where the state of a resource should be a known value
  class AvailabilityWindow
    attr_accessor :id
    attr_reader :key

    def initialize(id, base, store)
      @id = id
      @key = "#{base}/windows/#{id}"
      @store = store
      @start_time_private = CachedKey.new @store, "#{@key}/start_time", 10, '00:00'
      @end_time_private = CachedKey.new @store, "#{@key}/end_time", 10, '00:00'
      @available_private = CachedKey.new @store, "#{@key}/available", 0.1, 1
      @dow_private = CachedKey.new @store, "#{@key}/day_of_week", 10, -1
      @limit_private = CachedKey.new @store, "#{@key}/limit", 10, -1
    end

    def delete
      @store.delete(@key, dir: true, recursive: true)
    end

    def start_time
      Time.parse(@start_time_private.value)
    end

    def start_time=(val)
      if val.respond_to?(:hour)
        @start_time_private.value = "#{val.hour}:#{val.min}"
      else
        @start_time_private.value = val
      end
    end

    def day_of_week
      @dow_private.value.to_i
    end

    def day_of_week=(val)
      @dow_private.value = val.to_i
    end

    def limit
      @limit_private.value.to_i
    end

    def limit=(val)
      @limit_private.value = val.to_i
    end

    def end_time
      Time.parse(@end_time_private.value)
    end

    def end_time=(val)
      if val.respond_to?(:hour)
        @end_time_private.value = "#{val.hour}:#{val.min}"
      else
        @end_time_private.value = val
      end
    end

    def available?
      @available_private.value.to_i == 1
    end

    def available=(val)
      @available_private.value = (val ? 1 : 0)
    end

    def in_window?(ref_time = Time.now)
      ref_time = Time.parse(ref_time) unless ref_time.respond_to?(:hour)

      return false if (day_of_week != -1) && (day_of_week != ref_time.wday)

      # 'freezing' time so that we don't run into issues around midnight.
      time = Time.now

      # If we made it this far then the day of the week has already been addressed and only the
      # clock portion of the time matters
      ref_time = Time.parse(time.to_s.sub(/\d{2}:\d{2}:\d{2}/, "#{ref_time.hour}:#{ref_time.min}:00"))
      s_time = Time.parse(time.to_s.sub(/\d{2}:\d{2}:\d{2}/, "#{start_time.hour}:#{start_time.min}:00"))
      e_time = Time.parse(time.to_s.sub(/\d{2}:\d{2}:\d{2}/, "#{end_time.hour}:#{end_time.min}:00"))

      (ref_time >= s_time) && (ref_time <= e_time)
    end

  end
end
