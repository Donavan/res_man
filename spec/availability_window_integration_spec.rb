require 'spec_helper'


describe 'AvailabilityWindow, Integration' do

  clazz = ResMan::AvailabilityWindow


  let(:window_base) { '/test_resource_base' }
  let(:window_id) { 'test_window_id' }
  let(:backing_store) { Etcd.client }
  let(:window) { clazz.new(window_id, window_base, backing_store) }


  after(:each) do
    backing_store.delete(window_base, dir: true, recursive: true) if backing_store.exists?(window_base)
    Timecop.return
  end


  describe 'availability' do

    it 'stores its availability off of its key' do
      backing_store.delete(window.key, dir: true, recursive: true) if backing_store.exists?(window.key)

      window.available = false

      expect(backing_store.exists?("#{window.key}/available")).to be true
    end

    it 'starts off as available if the availability does not already exist in the backing store' do
      backing_store.delete(window.key, dir: true, recursive: true) if backing_store.exists?(window.key)

      window = clazz.new(window_id, window_base, backing_store)

      expect(window.available?).to eq(true)
    end

    it 'starts off with the current availability if the availability does already exist in the backing store' do
      window.available = false

      duplicate_window = clazz.new(window_id, window_base, backing_store)

      expect(duplicate_window.available?).to eq(false)
    end

    it 'can change its availability' do
      expect(window).to respond_to(:available=)

      window.available = true
      expect(window.available?).to eq(true)
      window.available = false
      expect(window.available?).to eq(false)
    end

  end

  describe 'start time' do

    it 'returns a Time object' do
      expect(window.start_time).to be_a(Time)
    end

    it 'stores its start time off of its key' do
      backing_store.delete(window.key, dir: true, recursive: true) if backing_store.exists?(window.key)

      window.start_time = '12:00'

      expect(backing_store.exists?("#{window.key}/start_time")).to be true
    end

    it 'starts with a start time of 00:00 if the start time does not already exist in the backing store' do
      backing_store.delete(window.key, dir: true, recursive: true) if backing_store.exists?(window.key)

      window = clazz.new(window_id, window_base, backing_store)
      start_time = window.start_time.strftime('%H:%M')

      expect(start_time).to eq('00:00')
    end

    it 'starts off with the current start time if the start time does already exist in the backing store' do
      window.start_time = '12:34'

      duplicate_window = clazz.new(window_id, window_base, backing_store)
      start_time = duplicate_window.start_time.strftime('%H:%M')

      expect(start_time).to eq('12:34')
    end

    it 'can change its start time' do
      expect(window).to respond_to(:start_time=)

      window.start_time = '12:00'
      expect(window.start_time.strftime('%H:%M')).to eq('12:00')
      window.start_time = '1:00'
      expect(window.start_time.strftime('%H:%M')).to eq('01:00')
    end

    it 'can use time objects for setting the start time' do
      time = Time.now

      window.start_time = time

      expect(window.start_time.hour).to eq(time.hour)
      expect(window.start_time.min).to eq(time.min)
    end


    it 'can use strings for the start time' do
      time = Time.now

      window.start_time = "#{time.hour}:#{time.min}"

      expect(window.start_time.hour).to eq(time.hour)
      expect(window.start_time.min).to eq(time.min)
    end

  end

  describe 'end time' do

    it 'returns a Time object' do
      expect(window.end_time).to be_a(Time)
    end

    it 'stores its end time off of its key' do
      backing_store.delete(window.key, dir: true, recursive: true) if backing_store.exists?(window.key)

      window.end_time = '12:00'

      expect(backing_store.exists?("#{window.key}/end_time")).to be true
    end

    it 'starts with an end time of 00:00 if the start time does not already exist in the backing store' do
      backing_store.delete(window.key, dir: true, recursive: true) if backing_store.exists?(window.key)

      window = clazz.new(window_id, window_base, backing_store)
      end_time = window.end_time.strftime('%H:%M')

      expect(end_time).to eq('00:00')
    end

    it 'starts off with the current end time if the start time does already exist in the backing store' do
      window.end_time = '12:34'

      duplicate_window = clazz.new(window_id, window_base, backing_store)
      end_time = duplicate_window.end_time.strftime('%H:%M')

      expect(end_time).to eq('12:34')
    end

    it 'can change its end time' do
      expect(window).to respond_to(:end_time=)

      window.end_time = '12:00'
      expect(window.end_time.strftime('%H:%M')).to eq('12:00')
      window.end_time = '1:00'
      expect(window.end_time.strftime('%H:%M')).to eq('01:00')
    end

    it 'can use time objects for setting the end time' do
      time = Time.now

      window.end_time = time

      expect(window.end_time.hour).to eq(time.hour)
      expect(window.end_time.min).to eq(time.min)
    end

    it 'can use strings for the end time' do
      time = Time.now

      window.end_time = "#{time.hour}:#{time.min}"

      expect(window.end_time.hour).to eq(time.hour)
      expect(window.end_time.min).to eq(time.min)
    end

  end

  describe 'day of week' do

    it 'stores its day of week off of its key' do
      backing_store.delete(window.key, dir: true, recursive: true) if backing_store.exists?(window.key)

      window.day_of_week = 5

      expect(backing_store.exists?("#{window.key}/day_of_week")).to be true
    end

    it 'starts off with no day of week if the day of week does not already exist in the backing store' do
      backing_store.delete(window.key, dir: true, recursive: true) if backing_store.exists?(window.key)

      window = clazz.new(window_id, window_base, backing_store)

      expect(window.day_of_week).to eq(-1)
    end

    it 'starts off with the current day of week if the day of week does already exist in the backing store' do
      window.day_of_week = 100

      duplicate_window = clazz.new(window_id, window_base, backing_store)

      expect(duplicate_window.day_of_week).to eq(100)
    end

    it 'can change its day of week' do
      expect(window).to respond_to(:day_of_week=)

      window.day_of_week = 1
      expect(window.day_of_week).to eq(1)
      window.day_of_week = 5
      expect(window.day_of_week).to eq(5)
    end

  end

  describe 'limit' do

    it 'stores its limit off of its key' do
      backing_store.delete(window.key, dir: true, recursive: true) if backing_store.exists?(window.key)

      window.limit = 5

      expect(backing_store.exists?("#{window.key}/limit")).to be true
    end

    it 'starts off with no limit if the limit does not already exist in the backing store' do
      backing_store.delete(window.key, dir: true, recursive: true) if backing_store.exists?(window.key)

      window = clazz.new(window_id, window_base, backing_store)

      expect(window.limit).to eq(-1)
    end

    it 'starts off with the current limit if the limit does already exist in the backing store' do
      window.limit = 100

      duplicate_window = clazz.new(window_id, window_base, backing_store)

      expect(duplicate_window.limit).to eq(100)
    end

    it 'can change its limit' do
      expect(window).to respond_to(:limit=)

      window.limit = 1
      expect(window.limit).to eq(1)
      window.limit = 5
      expect(window.limit).to eq(5)
    end

  end


  describe 'windows' do

    context 'not limited to a particular day of the week' do

      before(:each) do
        window.day_of_week = -1
      end

      it 'is in a window if the provided reference time is within the start and end times of the window' do
        window.start_time = Time.parse('01:00')
        window.end_time = Time.parse('02:00')

        expect(window.in_window?(Time.parse('01:00'))).to be true
        expect(window.in_window?(Time.parse('01:30'))).to be true
        expect(window.in_window?(Time.parse('02:00'))).to be true
      end

      it 'is not in a window if the provided reference time is not within the start and end times of the window' do
        window.start_time = Time.parse('01:00')
        window.end_time = Time.parse('02:00')

        expect(window.in_window?(Time.parse('00:59'))).to be false
        expect(window.in_window?(Time.parse('02:01'))).to be false
      end

    end

    context 'limited to a particular day of the week' do

      before(:each) do
        window.day_of_week = 3 # Wednesday
        Timecop.freeze(Time.parse('2015-05-06T12:00:00')) # A Wednesday
      end

      it 'is in a window if the provided reference time is within the start and end times of the window' do
        window.start_time = Time.parse('01:00')
        window.end_time = Time.parse('02:00')

        expect(window.in_window?(Time.parse('01:00'))).to be true
        expect(window.in_window?(Time.parse('01:30'))).to be true
        expect(window.in_window?(Time.parse('02:00'))).to be true
      end

      it 'is not in a window if the provided reference time is not within the start and end times of the window' do
        window.start_time = Time.parse('01:00')
        window.end_time = Time.parse('02:00')

        expect(window.in_window?(Time.parse('00:59'))).to be false
        expect(window.in_window?(Time.parse('02:01'))).to be false
      end

      it 'is not in a window if the provided reference time is not on the day of the week set by the window' do
        window.start_time = Time.parse('01:00')
        window.end_time = Time.parse('02:00')

        window.day_of_week = 6 # Saturday
        Timecop.freeze(Time.parse('2015-05-08T12:00:00')) # Not a Saturday

        expect(window.in_window?(Time.parse('01:00'))).to be false
        expect(window.in_window?(Time.parse('01:30'))).to be false
        expect(window.in_window?(Time.parse('02:00'))).to be false
      end

    end

    it 'can use time objects for the window reference time' do
      time = Time.parse('2015-05-05T12:00:00') # A Tuesday

      window.start_time = time - 600
      window.end_time = time + 600

      Timecop.freeze(Time.parse('2015-05-07T12:00:00')) # Thursday
      expect(window.in_window?(time)).to be true # Day of week day of reference time and 'now' doesn't matter. Clock time is within the window.

      window.day_of_week = 3 # Wednesday

      expect(window.in_window?(time)).to be false # Invalid day of week. Hour and minute time is irrelevant.
    end

    it 'can use strings for the window reference time' do
      time = Time.parse('2015-05-05T12:00:00') # A Tuesday

      window.start_time = time - 600
      window.end_time = time + 600

      Timecop.freeze(Time.parse('2015-05-07T12:00:00')) # Thursday
      expect(window.in_window?(time.to_s)).to be true # Day of week day of reference time and 'now' doesn't matter. Clock time is within the window.

      window.day_of_week = 3 # Wednesday

      expect(window.in_window?(time.to_s)).to be false # Invalid day of week. Hour and minute time is irrelevant.
    end

    it 'defaults to the current time if one is not provided' do
      time = Time.now
      window.start_time = time - 60
      window.end_time = time + 60

      expect(window.in_window?).to be true
    end

  end

  it 'is no longer in the backing store after deletion' do
    expect(backing_store.exists?(window.key)).to be true

    window.delete

    expect(backing_store.exists?(window.key)).to_not be true
  end

end
