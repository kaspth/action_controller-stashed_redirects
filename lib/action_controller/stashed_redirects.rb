# frozen_string_literal: true

require "active_support"

# Pass between different controller flows via stashed redirects
#
# Stash a redirect to execute a controller flow within another and return to the original flow later.
module ActionController::StashedRedirects
  extend ActiveSupport::Concern

  autoload :VERSION, "action_controller/stashed_redirects/version"

  # Allow a general `rescue ActionController::StashedRedirects::Error`.
  Error = Module.new

  class MissingRedirectError < StandardError
    include Error

    attr_reader :purpose

    def initialize(purpose)
      super "can't extract a stashed redirect_url to redirect_to"
      @purpose = purpose
    end
  end

  class_methods do
    # Adds a `before_action` to stash a redirect in a given `on:` action.
    #
    #   stash_redirect_for :sign_in, on: :new
    #   stash_redirect_for :sign_in, on: %i[ new edit ]
    #   stash_redirect_for :sign_in, on: :new, url: -> { update_post_path(@post) }
    def stash_redirect_for(purpose, on:, url: DEFAULT_URL)
      before_action(-> { stash_redirect_for(purpose, url: url) }, only: on)
    end
  end

  private
    # Stashes a redirect URL in the `session` under the given +purpose+.
    #
    # An explicit +redirect_url+ can be passed in `from:`, otherwise the redirect URL is
    # derived from `params[:redirect_url]` then falling back to `request.referer` on GET requests.
    #
    #   stash_redirect_for :sign_in
    #   stash_redirect_for :sign_in, from: url_from(params[:redirect_url]) || root_url
    #   stash_redirect_for :sign_in, from: :param   # Only derive the redirect URL from `params[:redirect_url]`.
    #   stash_redirect_for :sign_in, from: :referer # Only derive the redirect URL from `request.referer`.
    def stash_redirect_for(purpose, url: DEFAULT_URL)
      if url = derive_stash_redirect_url_from(url)
        session[KEY_GENERATOR.(purpose)] = url
      else
        raise ArgumentError, "missing a redirect_url to stash, pass one via from: or via a redirect_url URL param"
      end
    end

    # Finds and deletes the redirect stashed in `session` under the given +purpose+, then redirects.
    #
    #   redirect_from_stashed :sign_in
    #
    # Raises if no stashed redirect is found under the given +purpose+.
    #
    # Relies on +redirect_to+'s open redirect protection, see it's documentation for more.
    def redirect_from_stashed(purpose)
      redirect_to stashed_redirect_url_for(purpose)
    end

    # Deletes and returns the redirect stashed in the `session` under the given +purpose+ if any.
    #
    #   discard_stashed_redirect_for :sign_in # => the sign_in redirect URL or nil.
    def discard_stashed_redirect_for(purpose)
      session.delete(KEY_GENERATOR.(purpose))
    end

    def stashed_redirect_url_for(purpose)
      url_from(discard_stashed_redirect_for(purpose)) or raise MissingRedirectError, purpose
    end

    def derive_stash_redirect_url_from(url)
      case url
      when DEFAULT_URL  then redirect_url
      when String       then url_from url
      when Symbol, Proc then url_from instance_exec(self, &url)
      end
    end

    # Looks up a redirect URL from `params[:redirect_url]` using
    # `url_from` as the protection mechanism to ensure it's a valid internal redirect.
    #
    # Can be passed to `redirect_to` with a fallback:
    #
    #   redirect_to redirect_url || users_url
    def redirect_url = url_from(params[:redirect_url])

    DEFAULT_URL = Object.new

    KEY_GENERATOR = ->(purpose) { "__url_stash_#{purpose}" }
    private_constant :KEY_GENERATOR
end

ActiveSupport.on_load(:action_controller) { include ActionController::StashedRedirects }
