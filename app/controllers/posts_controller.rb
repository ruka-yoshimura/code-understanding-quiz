# frozen_string_literal: true

class PostsController < ApplicationController
  before_action :authenticate_user!, except: %i[show official]

  def show
    @post = Post.find(params[:id])
  end

  def official
    @posts = Post.joins(:user).where(users: { email: 'system@example.com' }).order(created_at: :desc)
  end

  def new
    @post = Post.new
  end

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      redirect_to @post, notice: 'コードを投稿しました！'
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def post_params
    params.require(:post).permit(:title, :content)
  end
end
