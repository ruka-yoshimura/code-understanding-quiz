class QuizzesController < ApplicationController
  before_action :authenticate_user!

  def create
    post = Post.find(params[:post_id])
    # 既存の問題文を取得して重複を避ける
    existing_questions = post.quizzes.pluck(:question)

    service = QuizGeneratorService.new(post.content, existing_questions)
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

    # 回答履歴を保存
    current_user.quiz_answers.create!(
      quiz: @quiz,
      correct: is_correct
    )

    # 正解の場合のみ継続日数を更新し、経験値を付与
    if is_correct
      current_user.update_streak!
      current_user.gain_xp(User::XP_PER_CORRECT_ANSWER)
    end

    render json: { status: 'ok', level: current_user.level, xp: current_user.xp }
  end
end
