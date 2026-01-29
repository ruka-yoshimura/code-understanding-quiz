class ReviewsController < ApplicationController
  before_action :authenticate_user!

  def index
    @quizzes = current_user.weak_quizzes
  end
end
