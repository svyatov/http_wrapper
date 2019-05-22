# http_wrapper

Simple wrapper around standard Net::HTTP library

[![Gem Version](https://badge.fury.io/rb/http_wrapper.svg)](https://badge.fury.io/rb/http_wrapper)
[![Build Status](https://travis-ci.org/svyatov/http_wrapper.svg?branch=master)](https://travis-ci.org/svyatov/http_wrapper)
[![Depfu](https://badges.depfu.com/badges/772e76ac2a71ed84291f452cd0e04b83/overview.svg)](https://depfu.com/github/svyatov/http_wrapper?project_id=6879)
[![Maintainability](https://api.codeclimate.com/v1/badges/41f8e8c507907ea20e2b/maintainability)](https://codeclimate.com/github/svyatov/http_wrapper/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/41f8e8c507907ea20e2b/test_coverage)](https://codeclimate.com/github/svyatov/http_wrapper/test_coverage)

---

## Installation

Add this line to your Gemfile:

```ruby
gem 'http_wrapper', '~> 3.0'
```

And then execute:

    $ bundle

Or install it manually:

    $ gem install http_wrapper

And require it in you code:

```ruby
require 'http_wrapper'
```

## Usage

Create wrapper object:

```ruby
http = HTTPWrapper.new
```

### Access unprotected resource located at **some_url**:

```ruby
response = http.get some_url

# response is always an instance of Net::HTTPResponse
```

Resource is redirecting? No problem! `http_wrapper` follows up to 10 sequential redirects by default.
But you can specify your own limits.

```ruby
http.max_redirects = 5
response = http.get some_url
```

Url doesn't have scheme? `http_wrapper` prefixes url with `http://` if scheme is missing.

```ruby
http.get 'example.com' # will correctly request 'http://example.com'
```

### Access resource protected by form-based authentication:

1. Post your credentials and get authentication cookie

    ```ruby
    # 'username' and 'password' fields are examples, it's just query parameters

    # credentials as body params
    cookie = http.post_and_get_cookie some_url, body: { username: 'iamjohn', password: '$uperS1kret' }
    # - or - credentials as GET query params
    cookie = http.post_and_get_cookie some_url, query: { username: 'iamjohn', password: '$uperS1kret' }
    ```

2. Get protected resource with provided cookie

    ```ruby
    response = http.get some_url, cookie: cookie
    ```

### Access resource protected by basic access authentication:

```ruby
response = http.get 'http://example.com', auth: { login: 'iamjohn', password: 'iamnotjohn' }
# => http://iamjohn:iamnotjohn@example.com
```

### Access resource mimicing AJAX

Add special header or use special method:

```ruby
response = http.get_ajax some_url
# - or -
response = http.get some_url, headers: { x_requested_with: 'XMLHttpRequest' }
# - or -
response = http.get some_url, headers: { 'X-Requested-With' => 'XMLHttpRequest' }
```

### Access JSON resource

Same as before :)

```ruby
response = http.get_json some_url
# - or -
response = http.get some_url, content_type: 'application/json; charset=UTF-8'
# - or -
response = http.get some_url, headers: { content_type: 'application/json; charset=UTF-8' }
# - or -
response = http.get some_url, headers: { 'Content-Type' => 'application/json; charset=UTF-8' }
```

### Access JSON resource mimicing AJAX

Just use special method :) (which sets `X-Requested-With` and `Content-Type` headers for you)

```ruby
response = http.get_ajax_json some_url, some_params
```

Difficult to remember what goes after what: `get_ajax_json` or `get_json_ajax`?
`http_wrapper` got you covered. They both work, use whatever variant you like better.

```ruby
# the same as above
response = http.get_json_ajax some_url, some_params
```

### Provide additional query parameters

Don't worry about escaping, `http_wrapper` got you covered here either.

```ruby
response = http.get 'http://www.google.com', query: { message: 'Hi! M&Ms!', user: 'iamjohn' }
# => http://www.google.com/?message=Hi!%20M%26Ms!&user=iamjohn
```

Don't worry about parameters that already in URL, they'll be merged.

```ruby
response = http.get 'http://www.google.com/?q=test', query: { user: 'iamjohn' }
# => http://www.google.com/?q=test&user=iamjohn
```

### Files upload

You can easily upload any number of files with `multipart/form-data` content type.

```ruby
http = HTTPWrapper.new
params = {
  multipart: [
    # ['file input field name', 'File instance or string', { filename: 'itsfile.jpg', content_type: '...' }]
    ['user_photo', File.read('user_photo.jpg'), { filename: 'photo.jpg' }],
    # last element is optional
    ['user_pic', File.open('user_pic.jpg')],
    # you can also specify other parameters
    ['user_name', 'john griffin']
  ],
  # or you can specify other parameters in body section
  # it will be merged with multipart data
  body: {
    user_age: 25
  }
}
response = http.post some_url, params
```

### Set timeout

By default timeout is set to 10 seconds.

```ruby
http.timeout = 5 # in seconds
# - or - on instantiation
http = HTTPWrapper.new timeout: 5
```

### Set logger

If you need to debug your requests, it's as simple as to say to `http_wrapper` where to output debug information.

```ruby
logger = Logger.new '/path/to/log_file'
http.logger = logger
# - or -
http = HTTPWrapper.new logger: $stdout
# - to switch logger off -
http.logger = nil
```

### Work over SSL

`http_wrapper` works with SSL out of the box and by default verifying domain SSL certificate.
But you can easily turn verification off if needed.

```ruby
http.verify_cert = false
# - or - on instantiation
http = HTTPWrapper.new verify_cert: false
```

### POST, PUT and DELETE requests

On each `get` method there are `post`, `put` and `delete` methods. Examples:

```ruby
http.post some_url, body: { user: 'iamjohn', password: 'secret' }
# - or -
http.put some_url, body: { user: 'iamjohn', password: 'secret' }
# - or -
http.delete some_url, query: { user: 'iamjohn' }
```

Default content type header for these requests is `application/x-www-form-urlencoded; charset=UTF-8`.

So for `get_ajax` there are `post_ajax`, `put_ajax` and `delete_ajax`.

For `get_soap` there are `post_soap`, `put_soap` and `delete_soap`.

For `get_json` there are `post_json`, `put_json` and `delete_json`.

And for `get_ajax_json`, there are `post_ajax_json`, `put_ajax_json` and `delete_ajax_json`.

### Change User Agent

```ruby
http = HTTWrapper.new user_agent: 'custom user agent'
# - or -
http.user_agent = 'custom user agent'
http.get sample_url
# - or -
http.get sample_url, user_agent: 'custom user agent'
# - or -
http.get sample_url, headers: { user_agent: 'custom user agent' }
# the last one always replaces other definitions
```

### Perform own custom Net::HTTP requests

```ruby
uri = URI 'http://example.com'

request = Net::HTTP::Head.new uri

http.execute request, uri
```

### Full params hash example

```ruby
{
  # Request Headers
  headers: {
    'Content-Type' => 'text/html',
    'X-Requested-With' => 'XMLHttpRequest',
    'User-Agent' => 'Chrome v123',
    # - or - use symbols
    content_type: 'text/xml',
    x_requested_with: 'XMLHttpRequest',
    user_agent: 'Chrome v123'
  },

  # Query Parameters
  query: {
    user: 'iamjohn',
    'user-stuff' => '123abc'
  },

  # Cookie
  cookie: 'all cookies in one string',

  # Basic authentication credentials
  auth: {
    login: 'iamjohn',
    password: 'secret'
  },

  # Request body
  body: 'as a string',
  # - or -
  body: {
    as: 'a hash'
  },

  # Shortcut for User-Agent header (headers hash takes precedence)
  user_agent: 'UserAgent v1.2.3',

  # Shortcut for Content-Type header (headers hash takes precedence)
  content_type: 'text/xml',

  # multipart/form-data for file uploads
  # the format of array of arrays is important here!
  multipart: [
    # you can use File object
    ['file_input_name', File.open('somefile.ext')],
    # - or - string and specify filename
    ['file_input_name', File.read('somefile.ext'), { filename: 'readme.txt' }],
    # - or - full format
    ['file_input_name', 'some file content', { filename: 'readme.txt', content_type: 'text/text' }],
    # - or - add other simple parameters
    ['user_name', 'john smith']
  ]
}
```

Don't worry if you mistype root parameters key. `http_wrapper` checks root parameters keys and instantiation options keys.
If any unknown options or parameters found, it raises the `UnknownKeyError` exception.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
