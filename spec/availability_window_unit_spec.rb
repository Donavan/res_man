require 'spec_helper'


describe 'AvailabilityWindow, Unit' do

  clazz = ResMan::AvailabilityWindow


  describe 'class level' do

    it 'requires an id, a base key and a backing store to create' do
      expect(clazz.instance_method(:initialize).arity).to eq(3)
    end

  end

  describe 'instance level' do

    let(:window_base) { '/test_resource_base' }
    let(:window_id) { 'test_id' }
    let(:mock_backing_store) { mock_store = double('mock backing store')
                               allow(mock_store).to receive(:exists?).and_return(true)
                               mock_store
                             }
    let(:window) { clazz.new(window_id, window_base, mock_backing_store) }


    it 'has an id' do
      expect(window).to respond_to(:id)
    end

    it 'can change its id' do
      expect(window).to respond_to(:id=)

      window.id = 'foo'
      expect(window.id).to eq('foo')
      window.id = 'bar'
      expect(window.id).to eq('bar')
    end

    it 'stores its id upon creation' do
      window = clazz.new('foobar', window_base, mock_backing_store)

      expect(window.id).to eq('foobar')
    end

    it 'has a key' do
      expect(window).to respond_to(:key)
    end

    it 'builds it key based on its base and id' do
      expect(window.key).to eq("#{window_base}/windows/#{window_id}")
    end

    it 'has a start time' do
      expect(window).to respond_to(:start_time)
    end

    it 'has an end time' do
      expect(window).to respond_to(:end_time)
    end

    it 'has a day of the week' do
      expect(window).to respond_to(:day_of_week)
    end

    it 'has an availability flag' do
      expect(window).to respond_to(:available?)
    end

    it 'has a limit' do
      expect(window).to respond_to(:limit)
    end

    it 'can determine if a time is within the window' do
      expect(window).to respond_to(:in_window?)
    end

    it 'can be provided a reference time when determining whether or not it is in a window' do
      expect(window.method(:in_window?).arity).to eq(-1)
    end

    it 'can delete itself from the backing store' do
      expect(window).to respond_to(:delete)
    end

  end
end
