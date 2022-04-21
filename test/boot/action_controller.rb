class ApplicationController < ActionController::Base
end

class SessionsController < ApplicationController
  stash_redirect_for :sign_in, on: :new

  def new
    head :no_content
  end

  def create
    redirect_from_stashed :sign_in
  end
end

class UsersController < ApplicationController
end
