class HomeController < ApplicationController
  def index
    if user_signed_in?
      @posts = current_user.posts.order(created_at: :desc)
    else
      @posts = [] # Landing page state
    end
  end
end
