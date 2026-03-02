# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## [Unreleased]

## [5.0.0] - 2026-03-02

### Changed

- **BREAKING:** Hash options replaced with keyword arguments across the entire public API
  - `HTTPWrapper.new(options = {})` → `HTTPWrapper.new(timeout:, verify_cert:, logger:, max_redirects:, user_agent:)`
  - All HTTP methods (`get`, `post`, `put`, `delete`) now accept keyword arguments instead of an options hash
  - Type-specific methods (`get_ajax`, `post_json`, etc.) forward `**kwargs` to the base methods
  - `post_and_get_cookie` accepts `**kwargs` forwarded to `post`
- **BREAKING:** Minimum Ruby version raised from 2.5 to 3.2
- `write_timeout` now set on HTTP connections (in addition to `read_timeout` and `open_timeout`)

### Removed

- **BREAKING:** `UnknownKeyError` class (keyword arguments handle unknown key validation natively)
- **BREAKING:** `Util` module (`validate_hash_keys`, `query_to_hash`, `hash_to_query`)
- Support for Ruby < 3.2

### Added

- CI testing against Ruby head, 4.0, 3.4, 3.3, and 3.2
- Integration test suite with live HTTP server for end-to-end coverage

## [4.0.0]

### Changed

- All development dependencies updated

### Removed

- Support for Ruby 2.3 and 2.4

### Added

- Ruby 2.7 to the Travis CI config
- `rubocop-performance` gem
- RuboCop rake task added to the default rake task

## [3.0.0]

### Changed

- Code refactored for RuboCop compliance

### Removed

- Support for Ruby 1.9–2.2 and Rubinius

### Added

- `rubocop` and `rubocop-rspec` gems for code quality
- `simplecov` gem for test coverage tracking

## [2.1.1]

### Changed

- `UnknownParameterError` renamed to `UnknownKeyError`
- Removed options and parameters validation code duplication

### Fixed

- `post_and_get_cookie` method (warning: HTTPResponse#response is obsolete)

## [2.1.0]

### Added

- Ability to perform custom `Net::HTTP` requests via `#execute`
- File uploads with `multipart/form-data` content type
- `:user_agent` and `:content_type` parameter shortcuts
- Ability to specify headers as symbols
- URL scheme auto-prefixing (`http://`) when missing
- `:max_redirects` option for redirect limits
- `:logger` option for request debugging

### Changed

- Default content type changed to `text/html`
- `:params` key changed to `:query`
- `:validate_ssl_cert` option renamed to `:verify_cert`
- Massive refactoring

### Removed

- `:ca_file` option
- `soap` methods (rare usage)
- `:method` key from params

### Fixed

- Incorrect content type for `DELETE` request
- Timeout should be set in seconds, not microseconds

## [2.0.0]

### Changed

- Gem rewritten completely and renamed to `http_wrapper`
- `#get_response` renamed to `#get`
- `#get_ajax_response` renamed to `#get_ajax`
- `#get_soap_response` renamed to `#get_soap`
- `#get_json_response` renamed to `#get_json`
- `#get_cookie` renamed to `#post_and_get_cookie`
- Constructor uses options hash instead of separate parameters
- Methods signature changed to `method(url, params)`
- Tests rewritten completely using `webmock` gem
- Development gem dependencies reduced

### Added

- `#post`, `#put`, `#delete` methods
- `#get_ajax_json`, `#post_ajax_json`, `#put_ajax_json`, `#delete_ajax_json` methods
- `#post_[ajax|soap|json]`, `#put_[ajax|soap|json]`, `#delete_[ajax|soap|json]` methods

## [1.1.1]

### Added

- Query parameter support
- Specs

## [1.1.0]

### Changed

- API change

### Added

- Documentation

## [1.0.1]

### Fixed

- Bug fix

## [1.0.0]

### Added

- Initial release

[Unreleased]: https://github.com/svyatov/http_wrapper/compare/v5.0.0...HEAD
[5.0.0]: https://github.com/svyatov/http_wrapper/compare/v4.0.0...v5.0.0
[4.0.0]: https://github.com/svyatov/http_wrapper/compare/v3.0.0...v4.0.0
[3.0.0]: https://github.com/svyatov/http_wrapper/compare/v2.1.1...v3.0.0
[2.1.1]: https://github.com/svyatov/http_wrapper/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/svyatov/http_wrapper/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/svyatov/http_wrapper/compare/v1.1.1...v2.0.0
[1.1.1]: https://github.com/svyatov/http_wrapper/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/svyatov/http_wrapper/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/svyatov/http_wrapper/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/svyatov/http_wrapper/releases/tag/v1.0.0
