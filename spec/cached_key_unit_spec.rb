require 'spec_helper'

describe 'CachedKey, Unit' do
  let(:clazz) { ResMan::CachedKey }

  describe 'class level' do

    it 'requires a backing store, a key, a time to live, and an optional initial value' do
      expect(clazz.instance_method(:initialize).arity).to eq(-4)
    end

  end

  describe 'instance level' do

    # let(:mock_backing_store) { double('mock backing store') }
    let(:key) { clazz.new('fake_backing_store', 'test_key', 0.5) }


    it 'has a value' do
      expect(key).to respond_to(:value)
      expect(key).to respond_to(:value=)
    end

    it 'can invalidate itself' do
      expect(key).to respond_to(:invalidate)
    end

    it 'knows if it has expired or not' do
      expect(key).to respond_to(:expired?)
    end

    it 'starts off as expired' do
      expect(key).to be_expired
    end

  end
end
