class ApplicationController < ActionController::Base
  skip_forgery_protection
end

class SessionsController < ApplicationController
  stash_redirect_for :sign_in,  on: :new
  stash_redirect_for :sign_out, on: :destroy, url: :users_url

  def new
    head :no_content
  end

  def create
    redirect_from_stashed :sign_in
  end

  def destroy
    redirect_from_stashed :sign_out
  end
end

module Sessions
  class RedirectsController < ApplicationController
    def create
      redirect_from_stashed :sign_in
    end

    def forward
      redirect_forward_or_to root_url
    end
  end
end
