Gem::Specification.new do |gem|
  gem.name = 'tinyimg'
  gem.version = '0.1.0'
  gem.summary = "Tiny and fast JPEG/PNG resizer and converter"
  gem.description = "Convert between JPEG/PNG and resize images, either all in memory or via disk.  Only required libgd to function."
  gem.has_rdoc = false
  gem.author = "Roger Nesbitt"
  gem.email = "roger@seriousorange.com"
  gem.homepage = "http://github.com/mogest/tinyimg"
  gem.license = 'MIT'

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- spec/*`.split("\n")
  gem.require_paths = ["lib"]
  gem.extensions    = %w(ext/tinyimg/extconf.rb)

  gem.required_ruby_version = '>= 2.1.0'

  gem.add_development_dependency "rspec", "~> 3.0"
end
