class QuizzesController < ApplicationController
  before_action :authenticate_user!

  def create
    post = Post.find(params[:post_id])
    # 既存の問題文を取得して重複を避ける
    existing_questions = post.quizzes.pluck(:question)

    service = QuizGeneratorService.new(post.content, existing_questions, current_user.level)
    quiz_data = service.call

    if quiz_data
      @quiz = post.quizzes.build(
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

  # クイズの回答を処理する
  def answer
    @quiz = Quiz.find(params[:id])
    is_correct = params[:is_correct]

    # Userモデルのメソッドで回答処理（履歴保存、XP付与、ストリーク更新）を実行
    result = current_user.answer_quiz(@quiz, is_correct)

    render json: {
      status: 'ok',
      level: current_user.level,
      xp: current_user.xp,
      xp_gained: result[:xp_gained],
      bonus_applied: result[:bonus_applied]
    }
  end
end
