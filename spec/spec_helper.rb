# frozen_string_literal: true

require 'bundler/setup'
require 'webmock/rspec'

if ENV['TRAVIS'] == 'true'
  require 'simplecov'
  SimpleCov.start
end

module HTTPWrapperSpecHelpers
  %i[get post put delete].each do |type|
    define_method("stub_#{type}") do |url, params = nil|
      if params
        stub_request(type, url).with(params)
      else
        stub_request(type, url)
      end
    end
  end

  def stub_redirects(url, amount_of_redirects)
    stub_get(url).to_return(status: 301, headers: { 'Location' => url })
                 .times(amount_of_redirects)
                 .then
                 .to_return(status: 200)
  end
end

RSpec.configure do |config|
  config.include HTTPWrapperSpecHelpers

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
