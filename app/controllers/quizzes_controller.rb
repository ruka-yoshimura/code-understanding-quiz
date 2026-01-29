# frozen_string_literal: true

class QuizzesController < ApplicationController
  before_action :authenticate_user!

  def show
    @quiz = Quiz.find(params[:id])
  end

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
    elsif service.error_type == :rate_limit
      redirect_to post_path(post), alert: 'APIの利用制限に達しました。1分ほど待ってから再度お試しください。'
    else
      redirect_to post_path(post), alert: 'AIによるクイズ生成に失敗しました。時間をおいて再度お試しください。'
    end
  end

  # クイズの回答を処理する
  def answer
    @quiz = Quiz.find(params[:id])
    Rails.logger.debug do
      "DEBUG: answer action called. Params is_correct: #{params[:is_correct].inspect} (Class: #{params[:is_correct].class})"
    end
    is_correct = params[:is_correct] == 'true'
    Rails.logger.debug { "DEBUG: Calculated is_correct boolean: #{is_correct}" }

    # Userモデルのメソッドで回答処理（履歴保存、XP付与、ストリーク更新）を実行
    @result = current_user.answer_quiz(@quiz, is_correct)

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
          new_title: view_context.user_title(current_user),
          streak_multiplier: @result[:streak_multiplier],
          daily_streak: @result[:daily_streak]
        }
      end
      format.turbo_stream
    end
  end
end
