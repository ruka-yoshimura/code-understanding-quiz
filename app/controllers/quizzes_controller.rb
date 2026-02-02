# frozen_string_literal: true

class QuizzesController < ApplicationController
  before_action :authenticate_user!

  def index
    # ユーザーが投稿したコードから生成されたクイズ一覧
    @quizzes = Quiz.joins(:post).where(posts: { user_id: current_user.id }).order(created_at: :desc)
    # 正解済みのクイズIDを取得して、ビューでの判定に使用
    @solved_quiz_ids = current_user.quiz_answers.where(correct: true).pluck(:quiz_id)
  end

  def show
    @quiz = Quiz.find(params[:id])
  end

  def create
    post = Post.find(params[:post_id])
    # 既存の問題文を取得して重複を避ける
    existing_questions = post.quizzes.pluck(:question)

    begin
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
      elsif service.error_type == :rate_limit
        redirect_to post_path(post), alert: 'APIの利用制限に達しました。1分ほど待ってから再度お試しください。'
      else
        # 生成失敗（APIエラーなど）時のフォールバック
        handle_api_error
      end
    rescue StandardError => e
      Rails.logger.error "Quiz generation error: #{e.message}"
      handle_api_error
    end
  end

  private

  def handle_api_error
    official_drill_exists = Post.joins(:user).exists?(users: { email: 'system@example.com' })
    if official_drill_exists
      redirect_to official_posts_path, alert: 'AI生成が一時的に利用できません。公式ドリルでXPを稼ぎましょう！'
    else
      redirect_to root_path, alert: 'AI生成が一時的に利用できません。'
    end
  end

  public

  def answer
    @quiz = Quiz.find(params[:id])
    is_correct = params[:is_correct] == 'true'

    # Userモデルのメソッドで回答処理（履歴保存、XP付与、ストリーク更新）を実行
    @result = current_user.answer_quiz(@quiz, is_correct)

    # 称号の変化を判定
    old_title = view_context.user_title_text(@result[:old_level])
    new_title = view_context.user_title_text(@result[:new_level])
    @result[:title_changed] = (old_title != new_title)
    @result[:new_title_text] = new_title

    respond_to do |format|
      format.json do
        render json: {
          status: 'ok',
          level: current_user.level,
          xp: current_user.xp,
          xp_gained: @result[:xp_gained],
          bonus_applied: @result[:bonus_applied],
          combo_bonus: @result[:combo_bonus],
          penalty_applied: @result[:penalty_applied],
          level_up: @result[:level_up],
          old_level: @result[:old_level],
          new_level: @result[:new_level],
          new_title: @result[:new_title_text],
          title_changed: @result[:title_changed],
          streak_multiplier: @result[:streak_multiplier],
          daily_streak: @result[:daily_streak]
        }
      end
      format.turbo_stream
    end
  end
end
