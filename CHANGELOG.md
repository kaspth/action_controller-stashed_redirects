## [Unreleased]

## [0.2.0] - 2022-04-21

- `stash_redirect_for` raises `ArgumentError` on invalid redirect URL

   Protects against storing a URL that `redirect_to` can't redirect to later.

- `redirect_from_stashed` raises `ActionController::StashedRedirects::MissingRedirectError`

  Useful to add a specific general fallback:

  ```ruby
  class ApplicationController < ActionController::Base
    rescue_from(ActionController::StashedRedirects::MissingRedirectError) { redirect_to root_url }
  end
  ```

## [0.1.0] - 2022-04-21

- Initial release
