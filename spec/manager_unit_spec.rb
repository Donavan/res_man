require 'spec_helper'
require 'etcd'

describe ResMan::Manager do
  clazz = ResMan::Manager

  def tef_env
    !ENV['TEF_ENV'].nil? ? ENV['TEF_ENV'].downcase : 'dev'
  end

  def base_key
    "/tef/#{tef_env}"
  end

  def tef_config
    !ENV['TEF_CONFIG'].nil? ? ENV['TEF_CONFIG'] : './config'
  end

  describe 'class level' do
    it 'requires a base key, a backing store and a client ID to create' do
      expect(clazz.instance_method(:initialize).arity).to eq(3)
    end
  end

  describe 'with no resources' do
    before(:all) do
      @client =  Etcd.client
      @client_id = 'CLIENT_ID'
    end

    before(:each) do
      @client.delete(base_key, dir: true, recursive: true)
      @mgr = clazz.new(base_key, @client, @client_id)
    end

    after(:each) do
      @client.delete(base_key, dir: true, recursive: true)
    end

    it 'creates the base key if it does not exist' do
      expect(@client.exists?(base_key)).to eq(true)
    end

  end

  describe 'while handling resources' do
    before(:all) do
      @client =  Etcd.client
      @client_id = 'CLIENT_ID'
    end

    before(:each) do

      (1..5).each do |id|
        res = ResMan::Resource.new("test_resource_#{id}", "/tef/#{tef_env}/resources", @client, @client_id)
        res.ref_limit = 10
      end
      @mgr = clazz.new(base_key, @client,@client_id)
    end

    after(:each) do
      @client.delete(base_key, dir: true, recursive: true)
    end

    it 'loads all resources' do
      expect(@mgr).to respond_to(:load_resources_from_store)
      expect(@mgr.resources.count).to eq(5)
      (1..5).each do |id|
        expect(@mgr.resources["test_resource_#{id}"].name).to eq("test_resource_#{id}")
      end
    end

    it 'can return all resources' do
      expect(@mgr).to respond_to(:resources)
    end

    it 'can add a reference' do
      expect(@mgr).to respond_to(:add_ref)

      expect(@mgr.add_ref('test_resource_2')).to eq(true)
      expect(@mgr.resources['test_resource_2'].ref_count).to eq(1)
    end

    it 'can add multiple references when given an array' do
      expect(@mgr.add_ref(%w(test_resource_2 test_resource_1))).to eq(true)
      expect(@mgr.resources['test_resource_2'].ref_count).to eq(1)
      expect(@mgr.resources['test_resource_1'].ref_count).to eq(1)
    end

    it 'will not add a ref to any resource if any resource listed is at the limit when given an array' do

      10.times do
        @mgr.add_ref('test_resource_1')
      end

      expect(@mgr.add_ref(%w(test_resource_2 test_resource_1))).to eq(false)
      expect(@mgr.resources['test_resource_2'].ref_count).to eq(0)
      expect(@mgr.resources['test_resource_1'].ref_count).to eq(10)
    end

    it 'can return a list of unavailable resources' do

      10.times do
        @mgr.add_ref('test_resource_1')
      end

      expect(@mgr.unavailable_resources).to match_array(['test_resource_1'])

      10.times do
        @mgr.add_ref('test_resource_2')
      end

      expect(@mgr.unavailable_resources).to match_array(['test_resource_1', 'test_resource_2'])

      @mgr.remove_ref('test_resource_1')
      expect(@mgr.unavailable_resources).to match_array(['test_resource_2'])
    end

    it 'can remove a reference' do
      expect(@mgr).to respond_to(:remove_ref)
      2.times do
        @mgr.add_ref('test_resource_2')
      end
      expect(@mgr.remove_ref('test_resource_2')).to eq(true)
      expect(@mgr.resources['test_resource_2'].ref_count).to eq(1)
    end

    it 'can remove multiple references when given an array' do
      2.times do
        @mgr.add_ref(%w(test_resource_2 test_resource_1))
      end

      expect(@mgr.remove_ref(%w(test_resource_2 test_resource_1))).to eq(true)
      expect(@mgr.resources['test_resource_2'].ref_count).to eq(1)
      expect(@mgr.resources['test_resource_1'].ref_count).to eq(1)
    end

    it 'can identify resources locked by the same client ID' do
      2.times do
        @mgr.add_ref(%w(test_resource_2 test_resource_1))
      end


      expect(@mgr.current_locks.count).to eq(4)  # Added two refs to two resources
    end

    it 'can release all resources locked by the same client ID' do
      2.times do
        @mgr.add_ref(%w(test_resource_2 test_resource_1))
      end

      @mgr.release_current_locks
      expect(@mgr.current_locks.count).to eq(0)
    end

  end
end
