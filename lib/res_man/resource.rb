require 'etcd'
require_relative 'availability_window'
require_relative 'cached_key'
module ResMan
  # A class representing a resource which can be reference counted.
  class Resource
    attr_reader :name, :client_id

    def initialize(name, base, store, client_id)
      @store = store
      @name = name
      @key = "#{base}/#{name}"
      @client_id = client_id.gsub('~', '')
      @locks_key = "#{@key}/locks"

      @store.safe_create(@key, dir: true)
      @store.safe_create("#{@key}/windows", dir: true)
      @store.safe_create(@locks_key, dir: true)

      @ref_count_private = CachedKey.new @store, "#{@key}/ref_count", 0.10
      @ref_limit_private = CachedKey.new @store, "#{@key}/ref_limit", 1
      @available_private = CachedKey.new @store, "#{@key}/available", 0.10, 1
      @source_private = CachedKey.new @store, "#{@key}/source", 1000, 'unknown'
    end

    def ref_count
      @ref_count_private.value.to_i
    end

    def ref_limit
      @ref_limit_private.value.to_i
    end

    def ref_limit=(val)
      @ref_limit_private.value = val.to_i
    end

    def source
      @source_private.value
    end

    def source=(val)
      @source_private.value = val
    end

    def available
      @available_private.value.to_i == 1
    end

    def available=(val)
      @available_private.value = (val ? 1 : 0)
    end

    def available?
      win = active_window
      unless win.nil?
        return false unless win.available?
        return ((ref_count < win.limit) || win.limit == -1) && available
      end

      return ((ref_count < ref_limit) || ref_limit == -1) && available if win.nil?
    end

    def add_window(start_time, end_time, available, limit = -1)
      win = ResMan::AvailabilityWindow.new next_window_id, @key, @store
      win.start_time = start_time
      win.end_time = end_time
      win.available = available
      win.limit = limit

      win
    end

    def remove_window(window)
      win_id = window.respond_to?(:id) ? window.id : window
      window = ResMan::AvailabilityWindow.new win_id, @key, @store
      window.delete
    end

    def active_window
      windows.select(&:in_window?).first
    end

    def windows
      wins = []
      window_entries.each do |entry|
        win = ResMan::AvailabilityWindow.new entry.key.split('/').last.to_i, @key, @store
        yield win if block_given?
        wins << win unless block_given?
      end
      wins unless block_given?
    end

    def add_ref
      return false unless available?
      new_count = ref_count + 1
      win = active_window
      limit = win.nil? ? ref_limit : win.limit
      return false if new_count > limit

      begin
        @ref_count_private.value = new_count
      rescue Etcd::TestFailed
        @ref_count_private.invalidate
        return add_ref
      rescue Exception => e
        STDERR.puts("Failed to add ref on #{@key}.\n#{e.message}\n#{e.backtrace}")
        return false
      end
      record_lock
      true
    end

    def remove_ref
      new_count = ref_count - 1
      return false if new_count < 0

      begin
        @ref_count_private.value = new_count
      rescue Etcd::TestFailed
        return remove_ref
      rescue Exception => e
        STDERR.puts("Failed to remove ref on #{@key}.\n#{e.message}\n#{e.backtrace}")
        return false
      end

      remove_newest_lock
      true
    end

    def window_entries
      @store.get("#{@key}/windows").children
    end

    def next_window_id
      win_array = windows
      return 1 if win_array.count == 0
      windows.max { |a, b| a.id <=> b.id }.id + 1
    end

    def record_lock
      cur_count = @ref_count_private.value.to_i
      @store.set("#{@locks_key}/#{@client_id}~#{Time.now.to_i}~#{cur_count}", value: cur_count)
    end

    def remove_newest_lock(wanted_id = nil)
      max_count = 0
      key_to_delete = nil

      current_locks(wanted_id).each do |lock|
        if lock[:ref_count].to_i > max_count
          key_to_delete = lock[:key]
        end
      end

      @store.delete(key_to_delete) unless key_to_delete.nil?
    end

    def release_current_locks(wanted_id = nil)
      max = current_locks(wanted_id).count
      if max > 0
        max.times do
          remove_ref
        end

      end
    end

    def current_locks(wanted_id = nil)
      locks = []
      wanted_id ||= @client_id
      @store.get("#{@locks_key}").children.each do |entry|
        cid, timestamp, lock_ref_count, = entry.key.split('/').last.split('~')
        locks << {:client_id => cid, :timestamp => timestamp, :ref_count => lock_ref_count, :key => entry.key} if cid == wanted_id
      end
      locks
    end


    private :available, :window_entries, :next_window_id, :record_lock
  end
end
