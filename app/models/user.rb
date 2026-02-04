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

  # 1回の正解で獲得できる経験値
  XP_PER_CORRECT_ANSWER = 10
  # 初見正解ボーナス
  FIRST_ATTEMPT_BONUS = 5
  # 3連続正解ボーナス
  COMBO_BONUS = 20
  # 連続正解の目標数
  COMBO_THRESHOLD = 3
  # 3連続不正解ペナルティ
  PENALTY_AMOUNT = 10
  # 連続不正解の閾値
  PENALTY_THRESHOLD = 3
  # レベル上限
  MAX_LEVEL = 50

  # クイズに回答し、結果に基づいて経験値やストリークを更新する
  def answer_quiz(quiz, is_correct)
    # 過去に回答したことがあるか確認（ボーナス判定用）
    has_answered_before = quiz_answers.exists?(quiz: quiz)
    old_level = level

    # 回答履歴を保存
    quiz_answers.create!(quiz: quiz, correct: is_correct)

    result = {
      xp_gained: 0,
      bonus_applied: false,
      combo_bonus: false,
      penalty_applied: false,
      level_up: false,
      old_level: old_level,
      new_level: old_level,
      streak_multiplier: 1.0,
      daily_streak: daily_streak
    }

    if is_correct
      # 正解の場合
      # 基本経験値
      total_xp = XP_PER_CORRECT_ANSWER

      # 初見正解ボーナス
      unless has_answered_before
        total_xp += FIRST_ATTEMPT_BONUS
        result[:bonus_applied] = true
      end

      # コンボ処理
      self.current_streak = current_streak.to_i + 1
      self.incorrect_streak = 0 # 不正解ストリークはリセット

      if current_streak >= COMBO_THRESHOLD
        total_xp += COMBO_BONUS
        result[:combo_bonus] = true
        self.current_streak = 0 # ボーナス付与後にリセット
      end

      # ストリークボーナス倍率の適用
      multiplier = streak_multiplier
      if multiplier > 1.0
        total_xp = (total_xp * multiplier).round
        result[:streak_multiplier] = multiplier
      end

      gain_xp(total_xp)
      update_streak!

      result[:xp_gained] = total_xp
      result[:new_level] = level
      result[:level_up] = true if level > old_level
      result[:daily_streak] = daily_streak
    else
      # 不正解の場合
      self.current_streak = 0 # 正解ストリークはリセット (コンボ終了)
      self.incorrect_streak = incorrect_streak.to_i + 1

      if incorrect_streak >= PENALTY_THRESHOLD
        lose_xp(PENALTY_AMOUNT)
        result[:penalty_applied] = true
        self.incorrect_streak = 0 # ペナルティ適用後にリセット
      end

      save!
    end

    result
  end

  # 現在の継続日数に基づくXP獲得倍率を計算
  # 1日目: 1.0倍, 2日目: 1.1倍, ... 6日目以降: 1.5倍（上限）
  def streak_multiplier
    ds = daily_streak.to_i
    return 1.0 if ds < 2

    # 2日目なら daily_streak=2 -> bonus 0.1
    # bonus = (daily_streak - 1) * 0.1
    bonus = (ds - 1) * 0.1

    # 最大 0.5 (合計 1.5倍) まで
    [1.0 + bonus, 1.5].min.round(1)
  end

  # 経験値を獲得し、必要ならレベルアップする
  def gain_xp(amount)
    self.xp = xp.to_i + amount

    # レベルアップ判定（ループで複数レベルアップにも対応）
    # レベル上限(50)に達している場合はレベルアップしない
    while level < MAX_LEVEL && xp >= required_xp_for_next_level
      self.xp -= required_xp_for_next_level
      self.level += 1
    end

    save!
  end

  # 経験値を減らす（ただし0未満にはならない、レベルダウンもしない）
  def lose_xp(amount)
    self.xp = [xp.to_i - amount, 0].max
    save!
  end

  # 次のレベルまでの必要経験値を計算
  def required_xp_for_next_level
    level_val = level.to_i
    level_val = 1 if level_val < 1
    level_val * 50
  end

  # 現在のレベルでの進捗率（パーセント）を計算
  def xp_progress_percentage
    [(xp.to_i.to_f / required_xp_for_next_level * 100).round, 100].min
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

  # 回答時に継続日数を更新する
  def update_streak!
    today = Time.current.to_date

    if last_answered_date == today
      # 今日すでに回答済みなら何もしない
    elsif last_answered_date == today - 1
      # 昨日回答していれば継続
      self.daily_streak = daily_streak.to_i + 1
    else
      # 1日以上空いていればリセット
      self.daily_streak = 1
    end

    self.last_answered_date = today
    save!
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

  def set_default_name
    self.name = email.split('@').first if name.blank? && email.present?
  end
end
