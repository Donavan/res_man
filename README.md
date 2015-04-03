# ResMan

A library for tracking resources in a distributed system.  At its core ResMan is a simple reference counting system backed by a distributed key/value store.  A resource is considered available if its count below its limit.  

Resource availability can also be set directly by setting the *available* field to false.  Resources that have had *available* set to false can not have references added to them.

Lastly, resources can have time windows where their availability is set.  Windows contain start/end times and a day of the week field, 0-6 starting on Sunday (with -1 indicating that only the time portion should be used).  



## Installation

ResMan requires an Etcd installation to use as it's backing storage.



Add this line to your application's Gemfile:

    gem 'res_man'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install res_man

## Usage

Create a new resource:

	```ruby
	
	```


## Contributing

1. Fork it ( https://github.com/[my-github-username]/res_man/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
