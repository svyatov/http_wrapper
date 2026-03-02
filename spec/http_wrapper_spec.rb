# frozen_string_literal: true

RSpec.describe HTTPWrapper do
  subject(:http) { described_class.new }

  let(:basic_auth_login) { 'balogin' }
  let(:basic_auth_password) { 'bapassword' }

  it 'defines all dynamic methods' do
    %i[get post put delete
       get_json post_json put_json delete_json
       get_ajax post_ajax put_ajax delete_ajax
       get_ajax_json post_ajax_json put_ajax_json delete_ajax_json
       get_json_ajax post_json_ajax put_json_ajax delete_json_ajax].each do |method|
      expect(http).to respond_to method
    end
  end

  describe 'HTTP' do
    let(:sample_url) { 'http://example.com' }

    describe 'Options' do
      it 'raises ArgumentError if initial options key is unknown' do
        expect do
          described_class.new(unknown_option: 'test')
        end.to raise_error ArgumentError
      end

      it 'raises ArgumentError if params key is unknown' do
        expect do
          http.get sample_url, unknown_param_key: 'test'
        end.to raise_error ArgumentError
      end

      it 'follows redirects no more then 10 times by default' do
        stub_redirects sample_url, 9
        response = http.get sample_url
        expect(response.code).to eq '200'

        stub_redirects sample_url, 10
        expect { http.get sample_url }.to raise_error HTTPWrapper::TooManyRedirectsError, 'Too many redirects!'
      end

      it 'follows redirects no more times then specified' do
        http.max_redirects = 5

        stub_redirects sample_url, 4
        response = http.get sample_url
        expect(response.code).to eq '200'

        stub_redirects sample_url, 5
        expect { http.get sample_url }.to raise_error HTTPWrapper::TooManyRedirectsError, 'Too many redirects!'
      end

      it 'uses logger' do
        require 'logger'
        logger = Logger.new StringIO.new
        allow(logger).to receive(:<<)
        http.logger = logger

        WebMock.allow_net_connect!
        begin
          http.get 'localhost'
        rescue StandardError
          # NOOP, rescue from "connection refused" and such
        end
        WebMock.disable_net_connect!

        expect(logger).to have_received(:<<).at_least(:once)
      end
    end

    describe 'GET' do
      it 'adds http uri scheme if missing' do
        stub_get sample_url
        http.get sample_url.delete_prefix('http://')
      end

      it 'hits provided url with default content type' do
        stub_get sample_url, headers: { HTTPWrapper::CONTENT_TYPE_HEADER_NAME => HTTPWrapper::DEFAULT_CONTENT_TYPE }
        http.get sample_url
      end

      it 'sets content type if provided' do
        stub_get sample_url, headers: { HTTPWrapper::CONTENT_TYPE_HEADER_NAME => 'Custom Content Type' }
        http.get sample_url, headers: { HTTPWrapper::CONTENT_TYPE_HEADER_NAME => 'Custom Content Type' }
        http.get sample_url, content_type: 'Custom Content Type'
        http.get sample_url,
                 headers: { HTTPWrapper::CONTENT_TYPE_HEADER_NAME => 'Custom Content Type' },
                 content_type: 'Should Be Overwritten'
      end

      it 'sets proper header for JSON requests' do
        stub_get sample_url, headers: HTTPWrapper::JSON_HEADER
        http.get_json sample_url
      end

      it 'sets proper header for AJAX requests' do
        params = {
          headers: {
            HTTPWrapper::CONTENT_TYPE_HEADER_NAME => HTTPWrapper::DEFAULT_CONTENT_TYPE
          }.merge(HTTPWrapper::AJAX_HEADER)
        }
        stub_get sample_url, params
        http.get_ajax sample_url
      end

      it 'sets proper headers for AJAX-JSON requests' do
        stub_get sample_url, headers: HTTPWrapper::AJAX_JSON_HEADER
        http.get_ajax_json sample_url
      end

      it 'correctlies escape query parameters' do
        stub_get "#{sample_url}/?param1=&param2=A%26B&param3=C%20%26%20D"
        http.get sample_url, query: { param1: '', param2: 'A&B', param3: 'C & D' }
      end

      it 'sets default user agent' do
        stub_get sample_url, headers: { HTTPWrapper::USER_AGENT_HEADER_NAME => HTTPWrapper::USER_AGENT }
        http.get sample_url
      end

      it 'changes user agent if provided' do
        custom_user_agent = 'Mozilla v1.2.3'
        stub_get sample_url, headers: { HTTPWrapper::USER_AGENT_HEADER_NAME => custom_user_agent }
        http.get sample_url, headers: { HTTPWrapper::USER_AGENT_HEADER_NAME => custom_user_agent }

        http.get sample_url, user_agent: custom_user_agent

        http.user_agent = custom_user_agent
        http.get sample_url

        expect do
          http.get sample_url, user_agent: 'abracadabra'
        end.to raise_error WebMock::NetConnectNotAllowedError

        expect do
          http.user_agent = 'another test'
          http.get sample_url
        end.to raise_error WebMock::NetConnectNotAllowedError
      end

      it 'precedences header user agent before params' do
        stub_get sample_url, headers: { HTTPWrapper::USER_AGENT_HEADER_NAME => 'TestUserAgent' }

        http.user_agent = 'Should Be Overwritten'
        http.get sample_url, headers: { HTTPWrapper::USER_AGENT_HEADER_NAME => 'TestUserAgent' }
      end

      it 'sends cookie if provided' do
        cookie_value = 'some cookie'
        stub_get sample_url, headers: { 'Cookie' => cookie_value }
        http.get sample_url, cookie: cookie_value
        http.get sample_url, headers: { 'Cookie' => cookie_value }
      end

      it 'uses headers cookie if both (headers and parameters) cookies provided' do
        stub_get sample_url, headers: { 'Cookie' => 'Custom cookie' }
        http.get sample_url, headers: { 'Cookie' => 'Custom cookie' }, cookie: 'should not use this one'
      end

      it 'hits provided url with basic auth' do
        stub_request(:get, sample_url).with(basic_auth: [basic_auth_login, basic_auth_password])
        http.get sample_url, auth: { login: basic_auth_login, password: basic_auth_password }
      end

      it 'merges query parameters and params should take precedence' do
        stub_get "#{sample_url}/?text=edf&time=16:44&user=test"
        http.get "#{sample_url}/?user=test&text=abc", query: { time: '16:44', text: 'edf' }
      end

      it 'equallies treat header as string and header as symbol' do
        custom_content_type = 'Some Content Type'
        stub_get sample_url, headers: { 'Content-Type' => custom_content_type }
        http.get sample_url, headers: { content_type: custom_content_type }
      end
    end

    describe 'POST' do
      it 'sets content type if provided' do
        stub_post sample_url, headers: { HTTPWrapper::CONTENT_TYPE_HEADER_NAME => 'Custom Content Type' }
        http.post sample_url, headers: { HTTPWrapper::CONTENT_TYPE_HEADER_NAME => 'Custom Content Type' }
      end

      it 'returns cookies after post' do
        cookie_value = 'some cookie'
        stub_post(sample_url, body: 'username=test&password=test')
          .to_return(headers: { 'Set-Cookie' => cookie_value })
        cookie = http.post_and_get_cookie sample_url, body: { username: 'test', password: 'test' }
        expect(cookie).to eq cookie_value
      end

      it 'hits provided url with default content type' do
        stub_post sample_url, headers: { HTTPWrapper::CONTENT_TYPE_HEADER_NAME => HTTPWrapper::POST_CONTENT_TYPE }
        http.post sample_url
      end

      it 'sets all possible parameters correctly' do
        stub_request(:post, "#{sample_url}/?a=b&c=d")
          .with(
            body: 'e=f&g=k',
            headers: {
              'Content-Type' => 'Custom content type',
              'User-Agent' => 'Custom user agent',
              'Cookie' => 'cookie',
              'X-Requested-With' => 'XMLHttpRequest'
            },
            basic_auth: %w[user passw]
          )

        http.post sample_url,
                  content_type: 'Custom content type',
                  user_agent: 'Custom user agent',
                  headers: { x_requested_with: 'XMLHttpRequest' },
                  query: { a: 'b', c: 'd' },
                  body: { e: 'f', g: 'k' },
                  auth: { login: 'user', password: 'passw' },
                  cookie: 'cookie'
      end
    end

    describe 'PUT' do
      it 'hits provided url with default content type' do
        stub_put sample_url, headers: { HTTPWrapper::CONTENT_TYPE_HEADER_NAME => HTTPWrapper::POST_CONTENT_TYPE }
        http.put sample_url
      end
    end

    describe 'DELETE' do
      it 'hits provided url with default content type' do
        stub_delete sample_url, headers: { HTTPWrapper::CONTENT_TYPE_HEADER_NAME => HTTPWrapper::DEFAULT_CONTENT_TYPE }
        http.delete sample_url
      end
    end

    describe 'Custom request instance' do
      it 'performs request for custom Net::HTTP request instance' do
        stub_request :head, sample_url
        uri = URI sample_url
        request = Net::HTTP::Head.new uri
        http.execute request, request.uri
      end
    end
  end

  describe 'HTTPS' do
    let(:sample_url) { 'https://example.com' }

    it 'hits provided url with HTTPS protocol' do
      stub_get sample_url
      http.get sample_url
    end
  end
end
