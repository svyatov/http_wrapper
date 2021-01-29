# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'http_wrapper/version'

Gem::Specification.new do |spec|
  spec.name          = 'http_wrapper'
  spec.version       = HTTPWrapper::VERSION
  spec.authors       = ['Leonid Svyatov', 'Alexander Shvets']
  spec.email         = 'leonid@svyatov.ru'
  spec.description   = 'Simple wrapper around standard Net::HTTP library with multipart/form-data file upload ability'
  spec.summary       = 'Simple wrapper around standard Net::HTTP library'
  spec.homepage      = 'http://github.com/svyatov/http_wrapper'
  spec.license       = 'MIT'

  spec.files         = Dir['Gemfile', 'LICENSE', 'README.md', 'CHANGELOG.md', 'Rakefile', 'lib/**/*']
  spec.test_files    = Dir['spec/*']
  spec.require_paths = %w[lib]

  spec.required_ruby_version = '>= 2.5.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec',   '~> 3.9'
  spec.add_development_dependency 'rubocop', '~> 1.9'
  spec.add_development_dependency 'rubocop-performance', '~> 1.5'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.38'
  spec.add_development_dependency 'simplecov', '~> 0.17.1'
  spec.add_development_dependency 'webmock', '~> 3.8'
end
