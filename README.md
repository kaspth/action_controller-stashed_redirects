# ActionController::StashedRedirects

Pass between different controller flows via stashed redirects

Stash a redirect to execute a controller flow within another and return to the original flow later.

## Usage

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate

  private
    def authenticate
      # Pass `redirect_url:` to pass the URL we're currently on.
      redirect_to new_session_url(redirect_url: request.url) unless Current.user
    end
end

class SessionsController < ApplicationController
  # Stash a redirect at the start of the session authentication flow,
  # from `params[:redirect_url]` automatically.
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

### Making a sudo authentication system

Consider a flow where you want to require super-user, or sudo, privileges for a given action, e.g. type in your password before you can change your credit card.

We'll make a `require_sudo` API that we can annotate our controller with like this:

```ruby
class Billing::CreditCardsController < ApplicationController
  require_sudo # Require sudo on all actions in this controller.
  # require_sudo_on :edit, :update # Or just for some actions.

  def edit
  end

  def update
    Current.user.billing.credit_cards.find(params[:id]).update!(credit_card_params)
  end
end
```

`require_sudo` or `require_sudo_on` can come from a controller concern like this:

```ruby
# app/controllers/concerns/sudo/examination.rb
module Sudo::Examination
  extend ActiveSupport::Concern

  class_methods do
    def require_sudo_on(*actions, **) = require_sudo(only: *actions, **)
    def require_sudo(...) = before_action(:require_sudo, ...)
  end

  private
    def require_sudo
      if sudo.exam_needed?
        raise "Non-get: can't redirect back here, make sure you do …something with an interstitial page?" unless request.get?
        redirect_to new_sudo_exams_url(redirect_url: request.url)
      end
    end

    def sudo = Sudo.new(session)
end

# Which we include in ApplicationController:
class ApplicationController < ActionController::Base
  include Sudo::Examination
end
```

Notice how in `redirect_to new_sudo_exams_url(redirect_url: request.original_url)` we're passing the `redirect_url:` along that `ActionController::StashedRedirects` will need.
It's pointing back to the page we're on, which required sudo authentication, so we can redirect back to it after the sudo exam has been passed.

Next up, we can add an in-memory PORO model to give the behavior some better names:

```ruby
# app/models/sudo.rb
class Sudo < Data.define(:store)
  def passed!
    store[:sudo_expires_at] = 15.minutes.from_now
  end

  def exam_needed?
    expires_at = store[:sudo_expires_at]
    expires_at.nil? || Time.parse(expires_at).past?
  end
end
```

Finally, we can add the authenticating sudo controller itself, where `stash_redirect_for` will use the `redirect_url:` from earlier:

```ruby
# app/controllers/sudo/exams_controller.rb
class Sudo::ExamsController < ApplicationController
  stash_redirect_for :sudo, on: :new

  def new
    redirect_from_stashed :sudo unless sudo.exam_needed?
  end

  def create
    if pass_sudo_exam?
      sudo.passed!
      redirect_from_stashed :sudo
    else
      render :new, status: :unprocessable_entity
    end
  end
  private def pass_sudo_exam? = Current.user.authenticate_password(params[:password])
end

# config/routes.rb
namespace :sudo do
  resources :exams
end
```

Users can now fill-in their password, which will hit `sudo/exams#create` and redirect them back to the edit form on the
credit cards flow if it's the correct password.

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
