$LOAD_PATH.unshift File.expand_path('lib', File.dirname(__FILE__))

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

task :default => :spec

RSpec::Core::RakeTask.new do |task|
  task.pattern = 'spec/**/*_spec.rb'
  task.verbose = false
end

