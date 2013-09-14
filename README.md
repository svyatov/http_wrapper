# http_wrapper

Simple wrapper around standard Net::HTTP library to simplify common http[s] tasks usage

[![Gem Version](https://badge.fury.io/rb/http_wrapper.png)](http://badge.fury.io/rb/http_wrapper)
[![Build Status](https://travis-ci.org/Svyatov/http_wrapper.png)](https://travis-ci.org/Svyatov/http_wrapper)
[![Dependency Status](https://gemnasium.com/Svyatov/http_wrapper.png)](https://gemnasium.com/Svyatov/http_wrapper)
[![Coverage Status](https://coveralls.io/repos/Svyatov/http_wrapper/badge.png)](https://coveralls.io/r/Svyatov/http_wrapper)

## Installation

Add this line to your Gemfile:

```ruby
gem 'http_wrapper', '~> 2.1.0'
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

Resource is redirecting? No problem! `http_wrapper` follows up to 10 sequential redirects (you cannot change that limit yet).

```ruby
response = http.get some_url
```

### Access resource protected by form-based authentication:

1. Post your credentials and get authentication cookie

    ```ruby
    # 'username' and 'password' fields are examples, it's just query parameters

    # credentials as body params
    cookie = http.post_and_get_cookie some_url, body: { username: 'iamjohn', password: '$uperS1kret' }
    # - or - credentials as GET query params
    cookie = http.post_and_get_cookie some_url, params: { username: 'iamjohn', password: '$uperS1kret' }
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
response = http.get some_url, headers: {'X-Requested-With' => 'XMLHttpRequest'}
# - or -
response = http.get_ajax some_url
```

### Access JSON resource

Same as before :)

```ruby
response = http.get some_url, headers: {'Content-Type' => 'application/json; charset=UTF-8'}
# - or -
response = http.get_json some_url
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
response = http.get 'http://www.google.com', query: {message: 'Hi! M&Ms!', user: 'iamjohn'}
# => http://www.google.com/?message=Hi!%20M%26Ms!&user=iamjohn
```

Don't worry about parameters that already in URL, they'll be merged.

```ruby
response = http.get 'http://www.google.com/?q=test', query: {user: 'iamjohn'}
# => http://www.google.com/?q=test&user=iamjohn
```

### Set timeout for wrapper:

```ruby
http.timeout = 15 # in seconds
# - or - on instantiation
http = HTTPWrapper.new timeout: 15
```

### Work over SSL

To work over SSL enable certificate validation before any calls:

```ruby
http.validate_ssl_cert = true
http.ca_file = '/path/to/your/ca_file'
# - or - on instantiation
http = HTTPWrapper.new ca_file: '/path/to/your/ca_file', validate_ssl_cert: true
```

### POST, PUT and DELETE requests

On each `get` method there are `post`, `put` and `delete` methods. Examples:

```ruby
http.post some_url, body: {user: 'iamjohn', password: 'secret'}
# - or -
http.put some_url, body: {user: 'iamjohn', password: 'secret'}
# - or -
http.delete some_url, query: {user: 'iamjohn'}
```

Default content type header for these requests is `application/x-www-form-urlencoded; charset=UTF-8`.

So for `get_ajax` there are `post_ajax`, `put_ajax` and `delete_ajax`.

For `get_soap` there are `post_soap`, `put_soap` and `delete_soap`.

For `get_json` there are `post_json`, `put_json` and `delete_json`.

And for `get_ajax_json`, there are `post_ajax_json`, `put_ajax_json` and `delete_ajax_json`.

### Full params hash example

```ruby
{
  # Request Headers
  headers: {
    'Content-Type' => 'text/html',
    'X-Requested-With' => 'XMLHttpRequest',
    'User-Agent' => 'Chrome v123'
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
  }
}
```

Don't worry if you mistype root parameters key. `http_wrapper` checks root parameters keys and instantiation options keys.
If any unknown options or parameters found, they raise the `UnknownParameterError` exception.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request