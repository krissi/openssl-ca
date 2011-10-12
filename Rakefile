require 'rubygems'
require 'rake'
require 'rake/testtask'

Rake::TestTask.new :test do |t|
	t.test_files = FileList['test/test*.rb']
	t.verbose = false
end

task :default => [:test] do
end
