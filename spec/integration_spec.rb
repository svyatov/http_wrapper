# frozen_string_literal: true

require 'webrick'
require 'webrick/https'
require 'json'

module IntegrationHelper
  HTTP_PORT  = 18_432
  HTTPS_PORT = 18_433

  module_function

  def base_url
    "http://localhost:#{HTTP_PORT}"
  end

  def ssl_url
    "https://localhost:#{HTTPS_PORT}"
  end

  def start_http_server
    server = WEBrick::HTTPServer.new(Port: HTTP_PORT, Logger: WEBrick::Log.new(File::NULL),
                                     AccessLog: [])
    mount_echo(server)
    mount_redirect(server)
    mount_cookie(server)
    mount_auth(server)
    Thread.new { server.start }
    wait_for_server(HTTP_PORT)
    server
  end

  def start_https_server
    key, cert = generate_self_signed_cert
    server = WEBrick::HTTPServer.new(
      Port: HTTPS_PORT, SSLEnable: true,
      SSLCertificate: cert, SSLPrivateKey: key,
      Logger: WEBrick::Log.new(File::NULL), AccessLog: []
    )
    mount_echo(server)
    Thread.new { server.start }
    wait_for_server(HTTPS_PORT)
    server
  end

  def generate_self_signed_cert
    key = OpenSSL::PKey::RSA.new(2048)
    cert = OpenSSL::X509::Certificate.new
    cert.subject = cert.issuer = OpenSSL::X509::Name.parse('/CN=localhost')
    cert.not_before = Time.now
    cert.not_after = Time.now + 3600
    cert.public_key = key.public_key
    cert.serial = 1
    cert.sign(key, OpenSSL::Digest.new('SHA256'))
    [key, cert]
  end

  def mount_echo(server)
    server.mount_proc('/echo') do |req, res|
      res['Content-Type'] = 'application/json'
      res.body = JSON.generate(
        method: req.request_method, path: req.path, query: req.query,
        headers: req.header.transform_values(&:first),
        body: req.body, content_type: req.content_type
      )
    end
  end

  def mount_redirect(server)
    server.mount_proc('/redirect') do |_req, res|
      res.set_redirect(WEBrick::HTTPStatus::Found, "#{base_url}/echo")
    end
  end

  def mount_cookie(server)
    server.mount_proc('/set_cookie') do |_req, res|
      res['Set-Cookie'] = 'test_cookie=hello; Path=/'
      res.body = 'ok'
    end
  end

  def mount_auth(server)
    server.mount_proc('/auth') do |req, res|
      WEBrick::HTTPAuth.basic_auth(req, res, 'Test') do |user, password|
        user == 'user' && password == 'pass'
      end
      res['Content-Type'] = 'application/json'
      res.body = JSON.generate(user: req.user)
    end
  end

  def wait_for_server(port, timeout: 5)
    deadline = Time.now + timeout
    loop do
      TCPSocket.new('localhost', port).close
      return
    rescue Errno::ECONNREFUSED
      raise "Server on #{port} failed to start" if Time.now > deadline

      sleep 0.05
    end
  end
end

RSpec.describe HTTPWrapper, :integration do # rubocop:disable RSpec/SpecFilePathFormat
  subject(:http) { described_class.new }

  # rubocop:disable RSpec/BeforeAfterAll, RSpec/InstanceVariable
  before(:all) do
    @http_server = IntegrationHelper.start_http_server
    @https_server = IntegrationHelper.start_https_server
  end

  after(:all) do
    @http_server&.shutdown
    @https_server&.shutdown
  end
  # rubocop:enable RSpec/BeforeAfterAll, RSpec/InstanceVariable

  before { WebMock.allow_net_connect! }
  after  { WebMock.disable_net_connect! }

  let(:base_url) { IntegrationHelper.base_url }
  let(:ssl_url)  { IntegrationHelper.ssl_url }

  it 'GETs with query params' do
    response = http.get "#{base_url}/echo", query: { foo: 'bar', baz: '1' }
    body = JSON.parse(response.body)
    expect(body['query']).to include('foo' => 'bar', 'baz' => '1')
  end

  it 'POSTs with hash body' do
    response = http.post "#{base_url}/echo", body: { key: 'value' }
    body = JSON.parse(response.body)
    expect(body['body']).to eq 'key=value'
  end

  it 'POSTs with string body' do
    json = '{"key":"value"}'
    response = http.post "#{base_url}/echo", body: json, content_type: 'application/json'
    body = JSON.parse(response.body)
    expect(body['body']).to eq json
  end

  it 'POSTs with multipart form' do
    response = http.post "#{base_url}/echo", multipart: [%w[field val]]
    body = JSON.parse(response.body)
    expect(body['content_type']).to include('multipart/form-data')
    expect(body['body']).to include('field')
  end

  it 'PUTs with body' do
    response = http.put "#{base_url}/echo", body: { a: 'b' }
    body = JSON.parse(response.body)
    expect(body['method']).to eq 'PUT'
    expect(body['body']).to eq 'a=b'
  end

  it 'follows redirects' do
    response = http.get "#{base_url}/redirect"
    body = JSON.parse(response.body)
    expect(body['path']).to eq '/echo'
  end

  it 'sends and receives custom headers' do
    response = http.get "#{base_url}/echo", headers: { 'X-Custom' => 'test-value' }
    body = JSON.parse(response.body)
    expect(body['headers']['x-custom']).to eq 'test-value'
  end

  it 'sends and receives cookies' do
    response = http.get "#{base_url}/set_cookie"
    cookie = response['set-cookie']
    expect(cookie).to include('test_cookie=hello')

    response = http.get "#{base_url}/echo", cookie: cookie.split(';').first
    body = JSON.parse(response.body)
    expect(body['headers']['cookie']).to include('test_cookie=hello')
  end

  it 'sends basic auth' do
    response = http.get "#{base_url}/auth", auth: { login: 'user', password: 'pass' }
    expect(response.code).to eq '200'
    body = JSON.parse(response.body)
    expect(body['user']).to eq 'user'
  end

  it 'rejects bad basic auth' do
    response = http.get "#{base_url}/auth", auth: { login: 'wrong', password: 'wrong' }
    expect(response.code).to eq '401'
  end

  it 'connects to HTTPS with verify_cert: false' do
    wrapper = described_class.new(verify_cert: false)
    response = wrapper.get "#{ssl_url}/echo"
    body = JSON.parse(response.body)
    expect(body['path']).to eq '/echo'
  end
end
