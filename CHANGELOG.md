# Changelog

## v2.1.1

* code refactoring
* fixed `post_and_get_cookie` method (warning: HTTPResponse#response is obsolete)
* `UnknownParameterError` renamed to `UnknownKeyError`
* removed options and parameters validation code duplication

## v2.1.0

* added ability to perform custom `Net::HTTP` requests

    ```ruby
    http = HTTPWrapper.new
    uri = URI 'http://example.com'

    # Ruby v2.0.0
    request = Net::HTTP::Head.new uri
    # Ruby v1.9.3
    request = Net::HTTP::Head.new uri.request_uri

    http.execute request, uri
    ```

* added ability to upload files with `multipart/form-data` content type

    ```ruby
    http = HTTPWrapper.new
    params = {
      multipart: [
        # ['file input field name', 'File instance or string', {filename: 'itsfile.jpg', content_type: '...'}]
        # last element is optional
        ['user_pic', File.open('user_pic.jpg')],
        ['user_photo', File.read('user_photo.jpg'), {filename: 'photo.jpg'}],
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

* fixed incorrect content type for `DELETE` request
* default content type changed to `text/html`
* added `:user_agent` and `:content_type` shortcuts

    ```ruby
    # you can specify now user agent like so:
    http = HTTWrapper.new user_agent: 'custom user agent'
    # - or -
    http.user_agent = 'custom user agent'
    http.get sample_url
    # - or -
    http.get sample_url, user_agent: 'custom user agent'
    ```

    ```ruby
    # you can specify now content type like so:
    http.get sample_url, content_type: 'text/html'
    ```

* added ability to specify headers as symbols

    ```ruby
    http.get some_url, headers: {x_requested_with: 'XMLHttpRequest'}
    # - the same as -
    http.get some_url, headers: {'X-Requested-With' => 'XMLHttpRequest'}
    ```

* added ability to fix urls without scheme with default http scheme

    ```ruby
    http.get 'example.com'
    # will correctly request http://example.com
    ```

* added `:max_redirects` option to specify redirect following limits
* added `:logger` option

    ```ruby
    log = Logger.new
    http = HTTPWrapper.new logger: log
    - or -
    http.logger = $stdout
    ```

* massive refactoring
* `:ca_file` option removed
* `:validate_ssl_cert` option renamed to `:verify_cert`
* `soap` methods removed due to rare usage
* `:method` key removed from params
* `:params` key changed to `:query`

    ```ruby
    http.get some_url, query: { user_id: 1, text: 'abcdefg' }
    ```

* fixed bug with timeout - it should be set in seconds, not microseconds

## v2.0.0

* Gem rewritten completely and renamed to 'http_wrapper'
* `#get_response` now simply `#get`
* `#get_ajax_response` now `#get_ajax`
* `#get_soap_response` now `#get_soap`
* `#get_json_response` now `#get_json`
* `#get_cookie` now `#post_and_get_cookie`
* new methods `#post`, `#put`, `#delete`,
* new methods `#get_ajax_json`, `#post_ajax_json`, `#put_ajax_json`, `#delete_ajax_json`
* new methods `#post_[ajax|soap|json]`, `#put_[ajax|soap|json]`, `#delete_[ajax|soap|json]`
* class constructor now use options hash as a parameter instead of separate parameters

    ```ruby
    # was
    accessor = ResourceAccessor.new(5000, '/path/to/ca_file', true)
    # now
    http = HTTWrapper.new(timeout: 5000, ca_file: '/path/to/ca_file', validate_ssl_cert: true)
    ```

* methods signature changed to `method(url, params)`
* development gem dependencies reduced
* tests rewritten completely using `webmock` gem
* changelog order reversed
* changelog file renamed to `CHANGELOG.md`

## v1.1.1

* Adding query parameter
* Adding specs

## v1.1.0

* Write documentation
* API change

## v1.0.1

* Bug fix

## v1.0.0

* Initial release
