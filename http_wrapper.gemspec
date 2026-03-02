# frozen_string_literal: true

require_relative 'lib/http_wrapper/version'

Gem::Specification.new do |spec|
  spec.name          = 'http_wrapper'
  spec.version       = HTTPWrapper::VERSION
  spec.authors       = ['Leonid Svyatov', 'Alexander Shvets']
  spec.email         = 'leonid@svyatov.ru'
  spec.description   = 'Simple wrapper around standard Net::HTTP library with multipart/form-data file upload ability'
  spec.summary       = 'Simple wrapper around standard Net::HTTP library'
  spec.homepage      = 'https://github.com/svyatov/http_wrapper'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*.rb'] + %w[CHANGELOG.md LICENSE README.md http_wrapper.gemspec]
  spec.require_paths = %w[lib]

  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata = {
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => 'https://github.com/svyatov/http_wrapper',
    'changelog_uri' => 'https://github.com/svyatov/http_wrapper/blob/master/CHANGELOG.md',
    'bug_tracker_uri' => 'https://github.com/svyatov/http_wrapper/issues'
  }
end
