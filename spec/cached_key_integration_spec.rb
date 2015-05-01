require 'spec_helper'

describe 'CachedKey, Integration' do

  let(:clazz) { ResMan::CachedKey }

  let(:backing_store) { Etcd.client }
  let(:key_name) { '/cache_key_test/key' }
  let(:time_to_live) { 0.5 }

  let(:key) { clazz.new(backing_store, key_name, time_to_live) }


  after(:each) do
    backing_store.delete(key_name) if backing_store.exists?(key_name)
  end


  it 'creates the key in the backing store when a value is set' do
    backing_store.delete(key_name) if backing_store.exists?(key_name)

    key.value = 42

    expect(backing_store.exists?(key_name)).to be(true)
    expect(backing_store.get(key_name).value.to_i).to eq(42)
  end

  it 'complains if its current value does not match the value in the backing store when updating' do
    key.value = 'foo'

    backing_store.set(key_name, value: 'bar')

    expect { key.value = 'baz' }.to raise_error
  end

  context 'expired key' do

    it 'returns nil if the key does not exist in the backing store' do
      backing_store.delete(key_name) if backing_store.exists?(key_name)

      # Force expiration
      key.invalidate

      expect(key.value).to be_nil
    end

    it 'returns the backing store value if the key does exist in the backing store' do
      key.value = 42
      backing_store.set(key_name, value: 43)

      # Force expiration
      key.invalidate

      expect(key.value.to_i).to eq(43)
    end

  end

  context 'non-expired key' do

    it 'returns the value from the cache instead of the backing store' do
      key.value = 42

      # Whether the key exists in the backing store...
      backing_store.set(key_name, value: 43)
      expect(key.value.to_i).to eq(42)

      # ...or not
      backing_store.delete(key_name)
      expect(key.value.to_i).to eq(42)
    end

  end

  describe 'key expiration' do

    it 'becomes unexpired when a new value is set' do
      expect(key).to be_expired

      key.value = 7

      expect(key).to_not be_expired
    end

    it 'becomes unexpired when its value is gotten' do
      expect(key).to be_expired

      backing_store.set(key_name, value: 43)
      key.value

      expect(key).to_not be_expired
    end

    it 'is expired upon invalidation' do
      key.value = 7
      expect(key).to_not be_expired

      key.invalidate

      expect(key).to be_expired
    end

    it "is expired when its 'time to live' has been exceeded" do
      time_to_live = 1
      key = clazz.new(backing_store, key_name, time_to_live)
      key.value = 42

      expect(key).to_not be_expired

      # todo - the timecop gem might be helpful for tests like this
      sleep (time_to_live + 1)

      expect(key).to be_expired
    end

  end

  describe 'initial value' do

    it 'will cache an initial value if one is provided' do
      key = clazz.new(backing_store, key_name, time_to_live, 'foo')

      backing_store.set(key_name, value: 'bar')

      expect(key.value).to eq('foo')
    end

    it 'will not cache an initial value if it is nil' do
      key = clazz.new(backing_store, key_name, time_to_live, nil)

      backing_store.set(key_name, value: 'bar')

      expect(key.value).to eq('bar')
    end

    it 'will not cache an initial value if it already exists in the backing store' do
      backing_store.set(key_name, value: 'bar')

      key = clazz.new(backing_store, key_name, time_to_live, 'foo')

      expect(key.value).to eq('bar')
    end

  end

end
