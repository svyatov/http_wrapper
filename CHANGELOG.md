# Changelog

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
