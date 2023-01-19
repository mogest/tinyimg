Gem::Specification.new do |gem|
  gem.name = 'tinyimg'
  gem.version = '0.1.5'
  gem.summary = "Tiny and fast JPEG/PNG cropping and resizing"
  gem.description = "Convert between JPEG/PNG, crop and resize images, either all in memory or via disk.  Only requires libgd to function."
  gem.author = "Mog Nesbitt"
  gem.email = "mog@seriousorange.com"
  gem.homepage = "http://github.com/mogest/tinyimg"
  gem.license = 'MIT'

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- spec/*`.split("\n")
  gem.require_paths = ["lib"]
  gem.extensions    = %w(ext/tinyimg/extconf.rb)

  gem.required_ruby_version = '>= 2.0.0'

  gem.add_development_dependency "rspec", "~> 3.0"
end
