# frozen_string_literal: true

require_relative "stashed_redirects/version"

# Pass between different controller flows via stashed redirects
#
# Stash a redirect to execute a controller flow within another and return to the original flow later.
module ActionController::StashedRedirects
  extend ActiveSupport::Concern

  class_methods do
    # Adds a before_action to stash a redirect for a given `on:` action.
    #
    #   stash_redirect_for :sudo_authentication, on: :new
    #
    #   Override the default logic to only allow the referer:
    #   stash_redirect_for :sudo_authentication, -> { request.referer }, on: :new
    def stash_redirect_for(purpose, from = nil, on:)
      before_action(-> { stash_redirect_for(purpose, from ? instance_exec(&from) : nil) }, only: on)
    end
  end

  # Stashes a redirect URL in the `session` under the given +purpose+.
  #
  # An explicit +redirect_url+ can be passsed, otherwise the redirect URL is
  # derived from `params[:redirect_url]` then falling back to `request.referer`.
  def stash_redirect_for(purpose, redirect_url = nil)
    if url = [ redirect_url, params[:redirect_url], request.referer ].find(&:present?)
      session[KEY_GENERATOR.(purpose)] = url
    else
      raise ArgumentError, "missing a redirect_url to stash, pass one as the second argument or via a redirect_url URL param"
    end
  end

  # Finds and deletes the redirect stashed in `session` under the given +purpose+, then redirects.
  #
  #   redirect_from_stashed :login
  #
  # Raises if no stashed redirect is found under the given +purpose+.
  #
  # Relies on +redirect_to+'s open redirect protection, see it's documentation for more.
  def redirect_from_stashed(purpose)
    redirect_to stashed_redirect_url_for(purpose)
  end

  # Deletes the redirect stashed in the `session` under the given +purpose+ and returns it if any.
  #
  #   discard_stashed_redirect_for :login # => the login redirect URL or nil.
  def discard_stashed_redirect_for(purpose)
    session.delete(KEY_GENERATOR.(purpose))
  end

  private
    KEY_GENERATOR = ->(purpose) { "__url_stash_#{purpose.hash}" } # Use hash to allow for longer names, but don't take up needless storage.
    private_constant :KEY_GENERATOR

    def stashed_redirect_url_for(purpose)
      raise ArgumentError, "can't extract a stashed redirect_url from session, none found" \
        unless redirect_url = discard_stashed_redirect_for(purpose)

      url_from(redirect_url)
    end
end
