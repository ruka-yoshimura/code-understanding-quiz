class QuizzesController < ApplicationController
  before_action :authenticate_user!

  def create
    post = Post.find(params[:post_id])

    service = QuizGeneratorService.new(post.content)
    quiz_data = service.call

    if quiz_data
      @quiz = Quiz.new(
        original_code: post.content,
        question: quiz_data['question'],
        answer: quiz_data['answer'],
        option_1: quiz_data['option_1'],
        option_2: quiz_data['option_2'],
        explanation: quiz_data['explanation']
      )

      if @quiz.save
        redirect_to @quiz, notice: 'クイズを作成しました！'
      else
        redirect_to post_path(post), alert: 'クイズの保存に失敗しました。'
      end
    else
      redirect_to post_path(post), alert: 'AIによるクイズ生成に失敗しました（混雑している可能性があります）。'
    end
  end

  def show
    @quiz = Quiz.find(params[:id])
  end
end
