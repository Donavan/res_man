require 'spec_helper'
require 'etcd'
require 'time'

describe ResMan::AvailabilityWindow do
  clazz = ResMan::AvailabilityWindow

  def tef_env
    !ENV['TEF_ENV'].nil? ? ENV['TEF_ENV'].downcase : 'dev'
  end

  def base_key
    "/tef/#{tef_env}/test_resources"
  end

  def res_key
    "#{base_key}/test_resource"
  end

  def tef_config
    !ENV['TEF_CONFIG'].nil? ? ENV['TEF_CONFIG'] : './config'
  end

  describe 'class level' do
    it 'requires an id, a base key and a backing store to create' do
      expect(clazz.instance_method(:initialize).arity).to eq(3)
    end
  end

  describe 'instance level' do
    before(:all) do
      @client =  Etcd.client
      @client_id = 'CLIENT_ID'
      @win = clazz.new(1, res_key, @client)
    end

    after(:all) do
      @client.delete(res_key, dir: true, recursive: true) if @client.exists?(res_key)
    end

    it 'has a start time' do
      expect(@win).to respond_to(:start_time)
      expect(@win).to respond_to(:start_time=)
    end

    it 'has an end time' do
      expect(@win).to respond_to(:end_time)
      expect(@win).to respond_to(:end_time=)
    end

    it 'has a day of the week' do
      expect(@win).to respond_to(:day_of_week)
      expect(@win).to respond_to(:day_of_week=)
    end

    it 'has an availability flag' do
      expect(@win).to respond_to(:available?)
      expect(@win).to respond_to(:available=)
    end

    it 'has a limit' do
      expect(@win).to respond_to(:limit)
      expect(@win).to respond_to(:limit=)
    end

    it 'can determine if a time is within the window' do
      expect(@win).to respond_to(:in_window?)
    end

    it 'can delete itself from the store' do
      expect(@win).to respond_to(:delete)
    end
  end

  describe 'without keys created' do
    before(:all) do
      @client =  Etcd.client
      @client_id = 'CLIENT_ID'
    end

    before(:each) do
      ResMan::Resource.new('test_resource',  base_key, @client, @client_id)
      @win = clazz.new(1, res_key, @client)
    end

    after(:each) do
      @client.delete(base_key, dir: true, recursive: true)
    end

    it 'can create the keys it needs' do
      expect(@client.exists?("#{res_key}/windows/1/start_time")).to eq(true)
      expect(@client.exists?("#{res_key}/windows/1/end_time")).to eq(true)
      expect(@client.exists?("#{res_key}/windows/1/day_of_week")).to eq(true)
      expect(@client.exists?("#{res_key}/windows/1/available")).to eq(true)
    end

  end

  describe 'instance level' do
    before(:all) do
      @client =  Etcd.client
      @client_id = 'CLIENT_ID'
    end

    def setup_window(subtract, add, include_day = false)
      ref_time = Time.now
      @win.start_time = ref_time - (subtract * 60)
      @win.end_time = ref_time + (add * 60)
      @win.day_of_week = ref_time.wday if include_day
      ref_time
    end

    before(:each) do
      ResMan::Resource.new('test_resource',  base_key, @client, @client_id)
      @win = clazz.new(1, res_key, @client)
    end

    after(:each) do
      @client.delete(base_key, dir: true, recursive: true)
    end

    it 'can use time objects for the time variables' do
      ref_time = setup_window(10, 20, true)
      start_time = ref_time - (10 * 60)
      end_time = ref_time + (20 * 60)
      expect(@win.start_time.hour).to eq(start_time.hour)
      expect(@win.start_time.min).to eq(start_time.min)
      expect(@win.end_time.hour).to eq(end_time.hour)
      expect(@win.end_time.min).to eq(end_time.min)
    end

    it 'has an available flag' do
      @win.available = true
      expect(@win.available?).to eq(true)
      @win.available = false
      expect(@win.available?).to eq(false)
    end

    it 'can use strings for the time variables' do
      ref_time = Time.now
      start_time = ref_time - (10 * 60)
      end_time = ref_time + (20 * 60)
      @win.start_time = "#{start_time.hour}:#{start_time.min}"
      @win.end_time = "#{end_time.hour}:#{end_time.min}"
      expect(@win.start_time.hour).to eq(start_time.hour)
      expect(@win.start_time.min).to eq(start_time.min)
      expect(@win.end_time.hour).to eq(end_time.hour)
      expect(@win.end_time.min).to eq(end_time.min)
    end

    it 'can determine if a time is within the window with a day of the week' do
      expect(@win.in_window?(setup_window(10, 20, true))).to eq(true)
    end

    it 'can determine if a time is within the window without a day of the week' do
      expect(@win.in_window?(setup_window(10, 10))).to eq(true)
    end

    it 'can determine if a time is outside the window without a day of the week' do
      expect(@win.in_window?(setup_window(-10, 20))).to eq(false)
    end

    it 'can determine if a time is outside the window with a day of the week' do
      ref_time = setup_window(10, 20)
      @win.day_of_week = ref_time.wday + 1

      expect(@win.in_window?(ref_time)).to eq(false)
    end

    it 'can delete itself from the store' do
      expect { @client.get(@win.key, dir: true) }.not_to raise_error
      @win.delete
      expect { @client.get(@win.key, dir: true) }.to raise_error(Etcd::KeyNotFound)
    end
  end
end
