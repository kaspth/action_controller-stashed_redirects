class SessionsController < ActionController::Base
  stash_redirect_for :sign_in, on: :new

  def new
  end

  def create
    redirect_from_stashed :sign_in
  end
end

class UsersController < ActionController::Base
end
