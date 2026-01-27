class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :posts, dependent: :destroy
  has_many :quiz_answers, dependent: :destroy

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

    # 回答履歴を保存
    quiz_answers.create!(quiz: quiz, correct: is_correct)

    result = { xp_gained: 0, bonus_applied: false, combo_bonus: false, penalty_applied: false }

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
      self.current_streak += 1
      self.incorrect_streak = 0 # 不正解ストリークはリセット

      if self.current_streak >= COMBO_THRESHOLD
        total_xp += COMBO_BONUS
        result[:combo_bonus] = true
        self.current_streak = 0 # ボーナス付与後にリセット
      end

      # ストリークボーナス倍率の適用
      # 2日目から発動: 2日=1.1倍, 3日=1.2倍 ... 最大1.5倍
      multiplier = streak_multiplier
      if multiplier > 1.0
        total_xp = (total_xp * multiplier).round
        result[:streak_multiplier] = multiplier
      end

      gain_xp(total_xp)
      update_streak!

      result[:xp_gained] = total_xp
    else
      # 不正解の場合
      self.current_streak = 0 # 正解ストリークはリセット (コンボ終了)
      # incorrect_streakがnilの場合に備えて0をセットする
      self.incorrect_streak = (self.incorrect_streak || 0) + 1

      if self.incorrect_streak >= PENALTY_THRESHOLD
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
    return 1.0 if daily_streak < 2

    # 2日目なら daily_streak=2 -> bonus 0.1
    # bonus = (daily_streak - 1) * 0.1
    bonus = (daily_streak - 1) * 0.1

    # 最大 0.5 (合計 1.5倍) まで
    [1.0 + bonus, 1.5].min.round(1)
  end

  # 経験値を獲得し、必要ならレベルアップする
  def gain_xp(amount)
    self.xp += amount

    # レベルアップ判定（ループで複数レベルアップにも対応）
    # レベル上限(50)に達している場合はレベルアップしない
    while self.level < MAX_LEVEL && xp >= required_xp_for_next_level
      self.xp -= required_xp_for_next_level
      self.level += 1
    end

    save!
  end

  # 経験値を減らす（ただし0未満にはならない、レベルダウンもしない）
  def lose_xp(amount)
    self.xp = [self.xp - amount, 0].max
    save!
  end

  # 次のレベルに必要な経験値を計算 (現在のレベル * 50)
  def required_xp_for_next_level
    level * 50
  end

  # 回答時に継続日数を更新する
  def update_streak!
    today = Time.current.to_date

    if last_answered_date == today
      # 今日すでに回答済みなら何もしない
    elsif last_answered_date == today - 1
      # 昨日回答していれば継続
      self.daily_streak += 1
    else
      # 1日以上空いていればリセット
      self.daily_streak = 1
    end

    self.last_answered_date = today
    save!
  end

  def self.guest
    find_or_create_by!(email: 'guest@example.com') do |user|
      user.password = SecureRandom.urlsafe_base64
      # 開発用に初期レベルを設定したければここで
    end
  end
end
