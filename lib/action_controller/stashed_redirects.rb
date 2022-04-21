# frozen_string_literal: true

require "active_support"
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
    #   stash_redirect_for :sign_in, from: :referer, on: :new
    #   stash_redirect_for :sign_in, from: -> { update_post_path(@post) }
    def stash_redirect_for(purpose, on:, from: nil)
      before_action(-> { stash_redirect_for(purpose, from: from.respond_to?(:call) ? instance_exec(&from) : from) }, only: on)
    end
  end

  # Stashes a redirect URL in the `session` under the given +purpose+.
  #
  # An explicit +redirect_url+ can be passsed, otherwise the redirect URL is
  # derived from `params[:redirect_url]` then falling back to `request.referer`.
  #
  #   stash_redirect_for :sign_in
  #   stash_redirect_for :sign_in, from: url_from(params[:redirect_url]) || root_url
  #   stash_redirect_for :sign_in, from: :param   # Only derive the redirect URL from `params[:redirect_url]`.
  #   stash_redirect_for :sign_in, from: :referer # Only derive the redirect URL from `request.referer`.
  def stash_redirect_for(purpose, from: nil)
    if url = derive_stash_redirect_url_from(from)
      session[KEY_GENERATOR.(purpose)] = url
    else
      raise ArgumentError, "missing a redirect_url to stash, pass one via from: or via a redirect_url URL param"
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

    def derive_stash_redirect_url_from(from)
      from ||= %i[ param referer ]
      { param: params[:redirect_url], referer: request.get? && request.referer }.values_at(*from).find(&:present?) || from
    end
end
