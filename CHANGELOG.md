## [Unreleased]

## [0.2.0] - 2022-04-21

- `redirect_from_stashed` raises `ActionController::StashedRedirects::MissingRedirectError`

  Useful to add a specific general fallback:

  ```ruby
  class ApplicationController < ActionController::Base
    rescue_from(ActionController::StashedRedirects::MissingRedirectError) { redirect_to root_url }
  end
  ```

## [0.1.0] - 2022-04-21

- Initial release
