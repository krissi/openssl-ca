Gem::Specification.new do |s|
	s.name				= "openssl-ca"
	s.version			= "1.0.2"
	s.platform			= Gem::Platform::RUBY
	s.authors			= ["Christian Haase"]
	s.summary			= "An (unfinished) implementation of 'openssl ca'"
	s.files				= Dir["Rakefile", ".gemtest", "{lib}/**/*.rb", "test/*.rb"]
	s.require_path		= 'lib'
	s.test_files		= Dir["test/test_*.rb"]

	s.add_dependency('sequel')
end
