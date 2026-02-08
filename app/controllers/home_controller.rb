# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @posts = if user_signed_in?
               current_user.posts.includes(:quizzes).order(created_at: :desc)
             else
               []
             end
  end
end
