require 'rspec'
require 'webmock/rspec'

$LOAD_PATH.unshift File.expand_path('../lib', File.dirname(__FILE__))

module HTTPWrapperSpecHelpers
  [:get, :post, :put, :delete].each do |type|
    define_method("stub_#{type.to_s}") do |url, params = nil|
      if params
        stub_request(type, url).with(params)
      else
        stub_request(type, url)
      end
    end
  end

  def stub_redirects(url, amount_of_redirects)
    stub_get(url).to_return(status: 301, headers: {'Location' => url})
                 .times(amount_of_redirects)
                 .then
                 .to_return(status: 200)
  end
end

RSpec.configure do |config|
  config.mock_with :mocha
  config.include HTTPWrapperSpecHelpers
end