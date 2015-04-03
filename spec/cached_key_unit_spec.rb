require 'spec_helper'

describe ResMan::CachedKey do
  clazz = ResMan::CachedKey

  describe 'class level' do
    it 'requires an etcd client, a key, a time to live and an optional initial value' do
      expect(clazz.instance_method(:initialize).arity).to eq(-4)
    end
  end

  describe 'instance level' do
    before(:all) do
      @client =  Etcd.client
      @keyname = '/cache_key_test/key'
      @res = clazz.new(@client, @keyname, 0.5)
    end

    after(:each) do
      @client.delete(@keyname, dir: true, recursive: true) if @client.exists?(@keyname)
    end

    it 'has a value' do
      expect(@res).to respond_to(:value)
      expect(@res).to respond_to(:value=)
    end
  end

  describe 'instance level' do
    before(:all) do
      @client =  Etcd.client
      @keyname = '/cache_key_test/key'
    end

    before(:each) do
      @res = clazz.new(@client, @keyname, 0.25)
    end

    after(:each) do
      @client.delete(@keyname) if @client.exists?(@keyname)
    end

    it 'returns nil if the key does not exist' do
      expect(@res.value).to be_nil
    end

    it 'returns the value if the key does exist' do
      @client.set(@keyname, value: 42)
      expect(@res.value.to_i).to eq(42)
    end

    it 'creates the key on write' do
      expect(@client.exists?(@keyname)).to be(false)
      @res.value = 43 # set a value so the cache gets populated.
      @client.delete(@keyname)
      @res.value = 42
      expect(@client.exists?(@keyname)).to be(true)
    end

    it 'returns the value from the cache if the value changes before the ttl is up' do
      @res.value = 42
      @client.set(@keyname, value: 43)
      expect(@res.value.to_i).to be(42)
    end

    it 'returns the actual value if the ttl is up' do
      @res.value = 42
      sleep 0.26
      @client.set(@keyname, value: 43)
      expect(@res.value.to_i).to be(43)
    end
  end
end
