# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :posts, dependent: :destroy
  has_many :quiz_answers, dependent: :destroy

  before_validation :set_default_name, on: :create

  validates :name, length: { maximum: 50 }

  include Experienceable

  # レベル上限
  MAX_LEVEL = 999
  # 1日のクイズ生成上限
  DAILY_QUIZ_LIMIT = 20

  # クイズを生成可能か判定（1日20回制限）
  def can_generate_quiz?
    reset_daily_generation_count_if_needed
    daily_quiz_generation_count < DAILY_QUIZ_LIMIT
  end

  # 本日の残り生成可能回数
  def remaining_quiz_generations
    reset_daily_generation_count_if_needed
    [DAILY_QUIZ_LIMIT - daily_quiz_generation_count, 0].max
  end

  # クイズ生成回数をインクリメント
  def increment_quiz_generation_count!
    reset_daily_generation_count_if_needed
    self.daily_quiz_generation_count += 1
    self.last_quiz_generated_at = Time.current
    save!
  end

  # ユーザーの学習統計を取得
  def learning_stats
    total = quiz_answers.count
    return { total_answers: 0, weak_count: 0, correct_rate: 0 } if total.zero?

    incorrect_count = quiz_answers.where(correct: false).count
    {
      total_answers: total,
      weak_count: weak_quizzes.count,
      correct_rate: (((total - incorrect_count).to_f / total) * 100).round
    }
  end

  # ユーザーが間違えたことのあるクイズを取得
  # （一度も正解していない、または最新の回答が不正解のもの）
  def weak_quizzes
    quiz_ids = quiz_answers.where(correct: false).pluck(:quiz_id).uniq
    correct_quiz_ids = quiz_answers.where(correct: true).pluck(:quiz_id).uniq

    # まだ正解していない、間違えたことのあるクイズID
    review_ids = quiz_ids - correct_quiz_ids
    Quiz.where(id: review_ids).order(created_at: :desc)
  end

  # デモユーザーを初期状態にリセット
  def cleanup_demo_data!
    initial_state = case email
                    when 'beginner@example.com'
                      { level: 1, xp: 40, daily_streak: 1, last_answered_date: Time.zone.today }
                    when 'expert@example.com'
                      { level: 49, xp: 2440, daily_streak: 15, last_answered_date: Time.zone.today }
                    else
                      return
                    end

    # ステータスと名前をリセット
    update!(
      name: nil,
      level: initial_state[:level],
      xp: initial_state[:xp],
      daily_streak: initial_state[:daily_streak],
      current_streak: 0,
      incorrect_streak: 0,
      last_answered_date: initial_state[:last_answered_date]
    )

    # 投稿データ（紐づくクイズも含む）と回答履歴を削除
    posts.destroy_all
    quiz_answers.destroy_all

    # 初期データを再投入
    DemoDataService.seed_for(self)

    reload
  end

  # デモユーザーかどうかを判定
  def demo_user?
    %w[beginner@example.com expert@example.com].include?(email)
  end

  # 表示用ユーザー名（名前がなければメールアドレスの@の前を返す）
  def display_name
    name.presence || email.split('@').first
  end

  private

  def reset_daily_generation_count_if_needed
    return if last_quiz_generated_at.blank?

    # 最後に生成した日が今日でないならリセット
    return unless last_quiz_generated_at.to_date < Time.current.to_date

    self.daily_quiz_generation_count = 0
  end

  def set_default_name
    self.name = email.split('@').first if name.blank? && email.present?
  end
end
