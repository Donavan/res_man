
module ResMan
  # Represents a window of time where the state of a resource should be a known value
  class AvailabilityWindow
    attr_accessor :id
    attr_reader :key

    def initialize(id, base, store)
      @id = id
      @key = "#{base}/windows/#{id}"
      @store = store
      @store.safe_create(@key, dir: true)
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
        @end_time_private.value =  val
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

      (ref_time >= start_time) &&  (ref_time <= end_time)
    end
  end
end
