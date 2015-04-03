module Etcd
  # Monkey patching the etcd client.
  class Client
    # Create a key but don't freak if it exists
    def safe_create(key, hash)
      begin
        create(key, hash)
      rescue Etcd::NodeExist
        return true
      end
      true
    end

    # Update a key with some sanity checking for
    def safe_update(key, new_value, prev_value = nil)

      begin
        if prev_value.nil?
          # On OSX at least, callign this with a nil previous value
          # will result in an unrecognized result from ETCD.
          # So we'll get the value here, which will trigger the KeyNotfound error.
          prev_value = get(key).value
        end

        test_and_set(key, value: new_value, prevValue: prev_value)
      rescue Etcd::KeyNotFound
        create(key)
        set(key, value: new_value)
      rescue Etcd::PrevValueRequired
        set(key, value: new_value)
      end
    end
  end
end
