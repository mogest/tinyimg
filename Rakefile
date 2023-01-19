require "rake/extensiontask"

Rake::ExtensionTask.new "tinyimg" do |ext|
  ext.lib_dir = "lib/tinyimg"
end

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task :default => [:compile, :spec]
rescue LoadError
  # no rspec available
end
