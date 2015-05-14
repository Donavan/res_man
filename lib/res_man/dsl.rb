require 'timeout'


module ResMan
  module DSL

    def initialize_resman_dsl(base, store, client_id)
      @res_man_manager = ResMan::Manager.new(base, store, client_id)
    end

    def with_resource(resource_name, timeout_in_seconds = 30)
      begin
        Timeout::timeout(timeout_in_seconds) {
          success = false

          until success
            success = @res_man_manager.add_ref(resource_name)
            sleep 1
          end
        }
      rescue Timeout::Error
        raise(Timeout::Error, "Timed out while trying to add a reference to the #{resource_name} resource.")
      end

      begin
        yield
      ensure
        begin
          # Releasing a reference should not take much time at all
          Timeout::timeout(5) {
            success = false

            until success
              success = @res_man_manager.remove_ref(resource_name)
              sleep 1
            end
          }
        rescue Timeout::Error
          raise(Timeout::Error, "Timed out while trying to remove a reference to the #{resource_name} resource.")
        end
      end
    end

  end
end
