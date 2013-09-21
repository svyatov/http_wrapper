require_relative 'spec_helper'

require 'http_wrapper'

describe HTTPWrapper do
  let(:basic_auth_login) { 'balogin' }
  let(:basic_auth_password) { 'bapassword' }

  it 'should define all dynamic methods' do
    [:get,           :post,           :put,           :delete,
     :get_json,      :post_json,      :put_json,      :delete_json,
     :get_ajax,      :post_ajax,      :put_ajax,      :delete_ajax,
     :get_ajax_json, :post_ajax_json, :put_ajax_json, :delete_ajax_json,
     :get_json_ajax, :post_json_ajax, :put_json_ajax, :delete_json_ajax].each do |method|
      subject.should be_respond_to method
    end
  end

  context 'HTTP' do
    let(:sample_url) { 'http://example.com' }
    let(:sample_url_with_basic_auth) { "http://#{basic_auth_login}:#{basic_auth_password}@example.com" }

    context 'Options' do
      it 'should raise UnknownParameterError if initial options key is unknown' do
        expect do
          HTTPWrapper.new unknown_option: 'test', maybe_this_known: '?'
        end.to raise_error HTTPWrapper::UnknownKeyError, 'Unknown keys: unknown_option, maybe_this_known'
      end

      it 'should raise UnknownParameterError if params key is unknown' do
        expect do
          subject.get sample_url, unknown_param_key: 'test', another_param_key: 'wow'
        end.to raise_error HTTPWrapper::UnknownKeyError, 'Unknown keys: unknown_param_key, another_param_key'
      end

      it 'should follow redirects no more then 10 times by default' do
        stub_redirects sample_url, 9
        response = subject.get sample_url
        response.code.should eql '200'

        stub_redirects sample_url, 10
        expect { subject.get sample_url }.to raise_error HTTPWrapper::TooManyRedirectsError, 'Too many redirects!'
      end

      it 'should follow redirects no more times then specified' do
        subject.max_redirects = 5

        stub_redirects sample_url, 4
        response = subject.get sample_url
        response.code.should eql '200'

        stub_redirects sample_url, 5
        expect { subject.get sample_url }.to raise_error HTTPWrapper::TooManyRedirectsError, 'Too many redirects!'
      end

      it 'should use logger' do
        require 'logger'
        logger = Logger.new StringIO.new
        logger.should_receive(:<<).at_least(:once)
        subject.logger = logger

        WebMock.allow_net_connect!
        begin
          subject.get 'localhost'
        rescue
          # NOOP, rescue from "connection refused" and such
        end
        WebMock.disable_net_connect!
      end
    end

    context 'GET' do
      it 'should add http uri scheme if missing' do
        stub_get sample_url
        subject.get sample_url.gsub(/\Ahttp:\/\//, '')
      end

      it 'should hit provided url with default content type' do
        params = { headers: {HTTPWrapper::HEADER::CONTENT_TYPE => HTTPWrapper::CONTENT_TYPE::DEFAULT} }
        stub_get sample_url, params
        subject.get sample_url
      end

      it 'should set content type if provided' do
        params = { headers: {HTTPWrapper::HEADER::CONTENT_TYPE => 'Custom Content Type'} }
        stub_get sample_url, params
        subject.get sample_url, params
        subject.get sample_url, content_type: 'Custom Content Type'
        subject.get sample_url, params.merge({content_type: 'Should Be Overwritten'})
      end

      it 'should set proper header for JSON requests' do
        params = { headers: HTTPWrapper::JSON_HEADER }
        stub_get sample_url, params
        subject.get_json sample_url
      end

      it 'should set proper header for AJAX requests' do
        params = {
          headers: {
            HTTPWrapper::HEADER::CONTENT_TYPE => HTTPWrapper::CONTENT_TYPE::DEFAULT
          }.merge(HTTPWrapper::AJAX_HEADER)
        }
        stub_get sample_url, params
        subject.get_ajax sample_url
      end

      it 'should set proper headers for AJAX-JSON requests' do
        params = { headers: HTTPWrapper::AJAX_JSON_HEADER }
        stub_get sample_url, params
        subject.get_ajax_json sample_url
      end

      it 'should correctly escape query parameters' do
        stub_get sample_url + '/?param1=&param2=A%26B&param3=C%20%26%20D'
        subject.get sample_url, query: {param1: '', param2: 'A&B', param3: 'C & D'}
      end

      it 'should set default user agent' do
        params = { headers: {HTTPWrapper::HEADER::USER_AGENT => HTTPWrapper::USER_AGENT} }
        stub_get sample_url, params
        subject.get sample_url
      end

      it 'should change user agent if provided' do
        custom_user_agent = 'Mozilla v1.2.3'
        params = { headers: {HTTPWrapper::HEADER::USER_AGENT => custom_user_agent} }
        stub_get sample_url, params
        subject.get sample_url, params

        subject.get sample_url, user_agent: custom_user_agent

        subject.user_agent = custom_user_agent
        subject.get sample_url

        expect do
          subject.get sample_url, user_agent: 'abracadabra'
        end.to raise_error WebMock::NetConnectNotAllowedError

        expect do
          subject.user_agent = 'another test'
          subject.get sample_url
        end.to raise_error WebMock::NetConnectNotAllowedError
      end

      it 'should precedence header user agent before params' do
        params = { headers: {HTTPWrapper::HEADER::USER_AGENT => 'TestUserAgent'} }
        stub_get sample_url, params

        subject.user_agent = 'Should Be Overwritten'
        subject.get sample_url, params
      end

      it 'should send cookie if provided' do
        cookie_value = 'some cookie'
        params = { headers: {'Cookie' => cookie_value} }
        stub_get sample_url, params
        subject.get sample_url, cookie: cookie_value
        subject.get sample_url, params
      end

      it 'should use headers cookie if both (headers and parameters) cookies provided' do
        params = { headers: {'Cookie' => 'Custom cookie'} }
        stub_get sample_url, params
        subject.get sample_url, params.merge({cookie: 'should not use this one'})
      end

      it 'should hit provided url with basic auth' do
        stub_get sample_url_with_basic_auth
        subject.get sample_url, auth: {login: basic_auth_login, password: basic_auth_password}
      end

      it 'should merge query parameters and params should take precedence' do
        stub_get sample_url + '/?text=edf&time=16:44&user=test'
        subject.get(sample_url + '/?user=test&text=abc', query: {time: '16:44', text: 'edf'})
      end

      it 'should equally treat header as string and header as symbol' do
        stub_get sample_url, { headers: {'Content-Type' => 'Some Content Type'} }
        subject.get sample_url, { headers: {content_type: 'Some Content Type'} }
      end
    end

    context 'POST' do
      it 'should set content type if provided' do
        params = { headers: {HTTPWrapper::HEADER::CONTENT_TYPE => 'Custom Content Type'} }
        stub_post sample_url, params
        subject.post sample_url, params
      end

      it 'should return cookies after post' do
        cookie_value = 'some cookie'
        params = { body: {username: 'test', password: 'test'} }
        stub_post(sample_url, params).to_return({headers: {'Set-Cookie' => cookie_value}})
        cookie = subject.post_and_get_cookie sample_url, params
        cookie.should eql cookie_value
      end

      it 'should hit provided url with default content type' do
        params = { headers: {HTTPWrapper::HEADER::CONTENT_TYPE => HTTPWrapper::CONTENT_TYPE::POST } }
        stub_post sample_url, params
        subject.post sample_url
      end

      it 'should set all possible parameters correctly' do
        stub_request(:post, 'http://user:passw@example.com/?a=b&c=d').
            with(body: {
            e: 'f',
            g: 'k'
        },
                 headers: {
                     'Content-Type' => 'Custom content type',
                     'User-Agent' => 'Custom user agent',
                     'Cookie' => 'cookie',
                     'X-Requested-With' => 'XMLHttpRequest'
                 })

        subject.post sample_url, content_type: 'Custom content type',
                     user_agent: 'Custom user agent',
                     headers: {x_requested_with: 'XMLHttpRequest'},
                     query: {a: 'b', c: 'd'},
                     body: {e: 'f', g: 'k'},
                     auth: {login: 'user', password: 'passw'},
                     cookie: 'cookie'
      end
    end

    context 'PUT' do
      it 'should hit provided url with default content type' do
        params = { headers: {HTTPWrapper::HEADER::CONTENT_TYPE => HTTPWrapper::CONTENT_TYPE::POST } }
        stub_put sample_url, params
        subject.put sample_url
      end
    end

    context 'DELETE' do
      it 'should hit provided url with default content type' do
        params = { headers: {HTTPWrapper::HEADER::CONTENT_TYPE => HTTPWrapper::CONTENT_TYPE::DEFAULT } }
        stub_delete sample_url, params
        subject.delete sample_url
      end
    end

    context 'Custom request instance' do
      it 'should perform request for custom Net::HTTP request instance' do
        stub_request :head, sample_url
        uri = URI sample_url

        if RUBY_VERSION =~ /\A2/
          request = Net::HTTP::Head.new uri
          subject.execute request, request.uri
        else
          # Ruby v1.9.3 doesn't understand full URI object, it needs just path :(
          request = Net::HTTP::Head.new uri.request_uri
          subject.execute request, uri
        end
      end
    end
  end

  context 'HTTPS' do
    let(:sample_url) { 'https://example.com' }

    it 'should hit provided url with HTTPS protocol' do
      stub_get sample_url
      subject.get sample_url
    end
  end
end

