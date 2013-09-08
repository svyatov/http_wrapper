# encoding: utf-8
require File.expand_path('../lib/http_wrapper/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = 'http_wrapper'
  spec.summary       = %q{Simple wrapper around standard Net::HTTP library}
  spec.description   = %q{Simple wrapper around standard Net::HTTP library to simplify common http[s] tasks usage}
  spec.email         = 'leonid@svyatov.ru'
  spec.authors       = ['Leonid Svyatov', 'Alexander Shvets']
  spec.homepage      = 'http://github.com/Svyatov/http_wrapper'

  spec.files         = Dir['Gemfile', 'LICENSE', 'README.md', 'CHANGELOG.md', 'Rakefile', 'lib/**/*', 'spec/*']
  spec.test_files    = Dir['spec/*']
  spec.require_paths = %w(lib)
  spec.version       = HTTPWrapper::VERSION.dup
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_development_dependency 'rspec',   '~> 2.14.1'
  spec.add_development_dependency 'webmock', '~> 1.13.0'
end

