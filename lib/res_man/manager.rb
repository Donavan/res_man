module ResMan
  # Some sugar to make working with resources a little easier.
  class Manager
    attr_reader :resources

    def initialize(base, store, client_id)
      @client_id = client_id.gsub('~', '')
      @resources = {}
      @store = store
      @base = "#{base}/resources"
      load_resources_from_store
    end

    def load_resources_from_store
      begin
        dir = @store.get(@base)
      rescue Etcd::KeyNotFound
        @store.create(@base, dir: true)
        return
      end

      dir.children.each do |child|
        if child.directory?
          name = child.key.split('/').last
          @resources[name] = Resource.new(name, @base, @store, @client_id)
        end
      end
    end

    def add_ref(resource)
      return add_multiple_refs(resource) if resource.is_a? Enumerable
      return resources[resource].add_ref if resources[resource]
      false
    end

    def remove_ref(resource)
      if resource.is_a? Enumerable
        resource.each do |res|
          resources[res].remove_ref if resources[res]
        end
      else
        if resources[resource]
          return resources[resource].remove_ref
        else
          return false
        end
      end

      true
    end

    def add_multiple_refs(res_list)
      added_refs = []
      should_rollback = false

      res_list.each do |res|
        unless resources[res].nil?
          if resources[res].add_ref
            added_refs << resources[res]
          else
            should_rollback = true
            break
          end
        end
      end

      if should_rollback
        added_refs.each(&:remove_ref)
        return false
      end

      true
    end

    def unavailable_resources
      resources.values.select { |res| !res.available? }.map(&:name)
    end

    def release_current_locks(wanted_id = nil)
      wanted_id ||= @client_id
      @resources.values.each do |res|
        res.release_current_locks(wanted_id) if res.current_locks.count > 0
      end
    end

    def current_locks(wanted_id = nil)
      wanted_id ||= @client_id
      locks = []
      @resources.values.each do |res|
        locks.push(*res.current_locks(wanted_id))
      end
      locks
    end

    private :add_multiple_refs
  end
end
