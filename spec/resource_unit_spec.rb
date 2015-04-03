require 'spec_helper'


describe ResMan::Resource do
  clazz = ResMan::Resource

  def tef_env
    !ENV['TEF_ENV'].nil? ? ENV['TEF_ENV'].downcase : 'dev'
  end

  def base_key
    "/tef/#{tef_env}/test_resources"
  end

  def tef_config
    !ENV['TEF_CONFIG'].nil? ? ENV['TEF_CONFIG'] : './config'
  end

  describe 'class level' do
    it 'requires a name, a base key, a backing store and a client ID to create' do
      expect(clazz.instance_method(:initialize).arity).to eq(4)
    end
  end

  describe 'instance level' do
    before(:all) do
      @client_id = 'CLIENT_ID'
      @client = Etcd.client
      @res = clazz.new('test_resource', base_key, @client, @client_id)
    end

    it 'has a readonly ref count' do
      expect(@res).to respond_to(:ref_count)
      expect(@res).to_not respond_to(:ref_count=)
    end

    it 'has a source' do
      expect(@res).to respond_to(:source)
      expect(@res).to respond_to(:source=)
    end

    it 'has a name' do
      expect(@res).to respond_to(:name)
    end

    it 'has a client ID' do
      expect(@res).to respond_to(:client_id)
    end

    it 'can add a reference' do
      expect(@res).to respond_to(:add_ref)
    end

    it 'can remove a reference' do
      expect(@res).to respond_to(:add_ref)
    end

    it 'has a limit' do
      expect(@res).to respond_to(:ref_limit)
      expect(@res).to respond_to(:ref_limit=)
    end

    it 'can determine if it is available' do
      expect(@res).to respond_to(:available?)
      expect(@res).to respond_to(:available=)
    end

    it 'can add a window' do
      expect(@res).to respond_to(:add_window)
    end

    it 'can remove add a window' do
      expect(@res).to respond_to(:remove_window)
    end

    it 'can list all windows' do
      expect(@res).to respond_to(:windows)
    end

    it 'can tell you the active window' do
      expect(@res).to respond_to(:active_window)
    end
  end

  describe 'without keys created' do
    before(:all) do
      @client = Etcd.client
      @client_id = 'CLIENT_ID'
    end

    before(:each) do
      @res = clazz.new('test_resource', "#{base_key}", @client, @client_id)
    end

    after(:each) do
      @client.delete(base_key, dir: true, recursive: true)
    end
  end

  describe 'instance level' do
    before(:all) do
      @client = Etcd.client
      @client_id = 'CLIENT_ID'
    end

    before(:each) do
      @res = clazz.new('test_resource', "#{base_key}", @client, @client_id)
      @res.ref_limit = 10
    end

    after(:each) do
      @client.delete(base_key, dir: true, recursive: true)
    end

    it 'has a limit' do
      @res.ref_limit = 20
      expect(@res.ref_limit).to eq(20)
    end

    it 'has a source' do
      @res.source = 'unit'
      expect(@res.source).to eq('unit')
    end

    it 'has a name' do
      expect(@res.name).to eq('test_resource')
    end

    it 'has a way to set override availability' do
      @res.available = false
      expect(@res.available?).to eq(false)

      @res.available = true
      expect(@res.available?).to eq(true)
    end

    it 'has a ref count' do
      expect(@res.ref_count).to eq(0)
    end

    it 'can add a reference' do
      @res.add_ref
      expect(@res.ref_count).to eq(1)
    end

    it 'can remove a reference' do
      @res.add_ref
      @res.add_ref
      @res.remove_ref
      expect(@res.ref_count).to eq(1)
    end

    it 'can determine if it is available due to ref counts' do
      expect(@res.available?).to eq(true)
      (1..10).each do
        @res.add_ref
      end
      expect(@res.available?).to eq(false)
    end

    it 'maintains correct ref counts even when another process is also making changes' do
      expect(@res.available?).to eq(true)
      @res.add_ref

      @client.set("/tef/#{tef_env}/test_resources/test_resource/ref_count", value: 9)
      @res.add_ref
      expect(@res.ref_count).to eq(10)

      @client.set("/tef/#{tef_env}/test_resources/test_resource/ref_count", value: 9)
      @res.remove_ref
      expect(@res.ref_count).to eq(8)
    end

    it 'will not add a ref if another process has the count at the limit' do
      @res.add_ref

      @client.set("/tef/#{tef_env}/test_resources/test_resource/ref_count", value: 10)
      expect(@res.add_ref).to eq(false)
    end

    it 'can determine if it is available due a window by count' do
      (1..5).each do
        @res.add_ref
      end
      expect(@res.available?).to eq(true)

      now = Time.now
      @res.add_window now - 600, now + 600, true, 5
      expect(@res.available?).to eq(false)
    end

    it 'can determine if it is available due a window by state' do
      (1..5).each do
        @res.add_ref
      end
      expect(@res.available?).to eq(true)

      now = Time.now
      @res.add_window now - 600, now + 600, false, 6
      expect(@res.available?).to eq(false)
    end

    it 'can add a window' do
      window = @res.add_window '11:00', '11:55', true, 10
      expect(window).to_not be_nil
      expect(@res.windows.count).to eq(1)
    end

    it 'can remove a window' do
      window = @res.add_window '11:00', '11:55', true, 10
      expect { @res.remove_window(window) }.to_not raise_error
      expect(@res.windows.count).to eq(0)
    end

    it 'can tell you the active window if there is one' do
      now = Time.now
      window = @res.add_window now - 600, now + 600, true, 10

      expect(@res.active_window.id).to eq(window.id)
    end

    it 'returns nil for the active window if there is not an active window' do
      now = Time.now
      @res.add_window now + 600, now + 610, true, 10

      expect(@res.active_window).to be_nil
    end

    it 'can iterate the windows' do
      start_time_1 = Time.parse '11:00'
      start_time_2 = Time.parse '12:00'
      @res.add_window start_time_1, '11:55', true, 10
      @res.add_window start_time_2, '12:55', false, 10
      res_list = []
      @res.windows do |win|
        res_list << win
      end

      expect(res_list.map(&:start_time)).to match_array([start_time_1, start_time_2])
    end

    it 'can get the current windows' do
      start_time_1 = Time.parse '11:00'
      start_time_2 = Time.parse '12:00'
      @res.add_window start_time_1, '11:55', true, 10
      @res.add_window start_time_2, '12:55', false, 10

      expect(@res.windows.map(&:start_time)).to match_array([start_time_1, start_time_2])
    end

    it 'determines the next window id' do
      @res.add_window '11:00', '11:55', true, 10

      expect(@res.send(:next_window_id)).to be(2)
    end

    it 'determines the next window id, when there are gaps' do
      @res.add_window '11:00', '11:55', true, 10
      w = @res.add_window '12:00', '12:55', true, 10
      @res.add_window '13:00', '13:55', true, 10

      @res.remove_window w

      expect(@res.send(:next_window_id)).to be(4)
    end


    it 'Can remove all references belonging to the current client_id' do
      (1..5).each do
        @res.add_ref
      end

      @res.release_current_locks

      expect(@res.send(:current_locks).count).to eq(0)
      expect(@res.send(:ref_count)).to eq(0)
    end

    it 'returns a list of locks' do
      (1..5).each do
        @res.add_ref
      end

      expect(@res.send(:current_locks).count).to eq(5)
    end

    it 'correctly removes locks when the ref count goes down' do
      (1..5).each do
        @res.add_ref
      end

      expect(@res.send(:current_locks).count).to eq(5)

      (1..5).each do
        @res.remove_ref
      end
      expect(@res.send(:current_locks).count).to eq(0)
    end

  end

end
