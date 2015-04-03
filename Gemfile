source 'https://rubygems.org'


# The gems that we use to test our stuff
def testing_gems
  gem 'rake'
  gem 'cucumber'
  gem 'rspec', '~> 3.0.0'
  gem 'simplecov'
  gem 'pry'
  gem 'pry-debugger'
end

# The development (i.e. source code) versions of gems that are (or are needed by) our stuff
def dev_gems
  gem 'etcd'
  gem 'res_man', path: '../res_man'
end

# The real (i.e. installed on the machine) versions gems that are (or are needed by) our stuff
def test_gems
  gem 'etcd'
  gem 'res_man'
end

# Nothing new to see here.
def prod_gems
  test_gems
end

puts "Bundler mode: #{ENV['BUNDLE_MODE']}"
mode = ENV['BUNDLE_MODE']

case mode
  when 'dev'
    testing_gems
    dev_gems
  when 'test', 'prod'
    testing_gems
    test_gems
  when 'prod'
    prod_gems
  else
    raise(ArgumentError, "Unknown bundle mode: #{mode}. Must be one of dev/test/prod.")
end
