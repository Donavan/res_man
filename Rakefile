require 'bundler/gem_tasks'
require 'cucumber/rake/task'
require 'rspec/core/rake_task'

def set_cucumber_options(options)
  ENV['CUCUMBER_OPTS'] = options
end

def combine_options(set_1, set_2)
  set_2 ? "#{set_1} #{set_2}" : set_1
end

namespace 'res_man' do

  namespace 'cucumber' do
    desc 'Run all Cucumber tests for the gem'
    task :tests, [:command_options] do |_t, args|
      set_cucumber_options(combine_options('-t ~@wip -t ~@off', args[:command_options]))
    end
    Cucumber::Rake::Task.new(:tests)
  end

  namespace 'rspec' do
    desc 'Run all RSpec tests for the gem'
    RSpec::Core::RakeTask.new(:specs, :command_options) do |t, args|
      t.rspec_opts = '-t ~wip -t ~off --color '
      t.rspec_opts << args[:command_options] if args[:command_options]
    end
  end

  desc 'Run All The Things'
  task :everything do
    Rake::Task['res_man:rspec:specs'].invoke
    Rake::Task['res_man:cucumber:tests'].invoke
    Rake::Task['res_man:build'].invoke
  end

  desc 'Test All The Things'
  task :test_everything, [:command_options] do |_t, args|
    Rake::Task['res_man:rspec:specs'].invoke(args[:command_options])
    Rake::Task['res_man:cucumber:tests'].invoke(args[:command_options])
  end

  desc 'Build the gem'
  task :build do
    system 'gem build res_man.gemspec'
  end

  desc 'Push the compiled gem to geminabox'
  task :inabox do
    system "gem inabox -o pkg/res_man-#{ResMan::VERSION}.gem"
  end

end

task default: 'res_man:test_everything'
