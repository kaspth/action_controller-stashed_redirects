# ActionController::StashedRedirects

Pass between different controller flows via stashed redirects

Stash a redirect to execute a controller flow within another and return to the original flow later.

## Usage

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate

  private
    def authenticate
      redirect_to new_session_url unless Current.user
    end
end

class SessionsController < ApplicationController
  # Stash a redirect at the start of the session authentication flow,
  # from either params[:redirect_url] or request.referer in that order.
  stash_redirect_for :sign_in, on: :new

  def new
  end

  def create
    if User.authenticate_by(session_params)
      # On success, redirect the user back to where they first tried to access before being authenticated.
      redirect_from_stashed :sign_in
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

See the internal documentation for more usage information.

Only internal redirects are allowed, so attackers can't pass an external `redirect_url`.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add action_controller-stashed_redirects

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install action_controller-stashed_redirects

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kaspth/action_controller-stashed_redirects.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
