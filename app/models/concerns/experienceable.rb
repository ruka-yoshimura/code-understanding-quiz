# frozen_string_literal: true

module Experienceable
  extend ActiveSupport::Concern

  included do
    # 1回の正解で獲得できる経験値
    const_set(:XP_PER_CORRECT_ANSWER, 10)
    # 初見正解ボーナス
    const_set(:FIRST_ATTEMPT_BONUS, 5)
    # 3連続正解ボーナス
    const_set(:COMBO_BONUS, 20)
    # 連続正解の目標数
    const_set(:COMBO_THRESHOLD, 3)
    # 3連続不正解ペナルティ
    const_set(:PENALTY_AMOUNT, 10)
    # 連続不正解の閾値
    const_set(:PENALTY_THRESHOLD, 3)
  end

  # 通算獲得XP
  def total_xp
    if level <= 50
      (25 * level * (level - 1)) + xp.to_i
    else
      61_250 + ((level - 50) * 2500) + xp.to_i
    end
  end

  # 次のレベルまでの残りXP
  def xp_until_next_level
    [required_xp_for_next_level - xp.to_i, 0].max
  end

  # クイズに回答し、結果に基づいて経験値やストリークを更新する
  def answer_quiz(quiz, is_correct)
    old_level = level
    quiz_answers.create!(quiz: quiz, correct: is_correct)
    result = { xp_gained: 0, bonus_applied: false, combo_bonus: false, penalty_applied: false,
               level_up: false, old_level: old_level, new_level: old_level,
               streak_multiplier: 1.0, daily_streak: daily_streak }

    if is_correct
      apply_correct_answer!(quiz, result)
    else
      apply_incorrect_answer!(result)
    end
    result
  end

  # 現在の継続日数に基づくXP獲得倍率を計算
  def streak_multiplier
    ds = daily_streak.to_i
    return 1.0 if ds < 2

    [1.0 + ((ds - 1) * 0.1), 1.5].min.round(1)
  end

  # 経験値を獲得し、必要ならレベルアップする
  def gain_xp(amount)
    self.xp = xp.to_i + amount
    while level < User::MAX_LEVEL && xp >= required_xp_for_next_level
      self.xp -= required_xp_for_next_level
      self.level += 1
    end
    save!
  end

  # 経験値を減らす
  def lose_xp(amount)
    self.xp = [xp.to_i - amount, 0].max
    save!
  end

  # 次のレベルまでの必要経験値を計算
  def required_xp_for_next_level
    level_val = [level.to_i, 1].max
    [level_val, 50].min * 50
  end

  # 現在のレベルでの進捗率
  def xp_progress_percentage
    [(xp.to_i.to_f / required_xp_for_next_level * 100).round, 100].min
  end

  # 回答時に継続日数を更新する
  def update_streak!
    today = Time.current.to_date
    if last_answered_date == today - 1
      self.daily_streak = daily_streak.to_i + 1
    elsif last_answered_date != today
      self.daily_streak = 1
    end
    self.last_answered_date = today
    save!
  end

  private

  def apply_correct_answer!(quiz, result)
    gained = self.class::XP_PER_CORRECT_ANSWER
    unless quiz_answers.where(quiz: quiz).many?
      gained += self.class::FIRST_ATTEMPT_BONUS
      result[:bonus_applied] = true
    end
    self.current_streak = current_streak.to_i + 1
    self.incorrect_streak = 0
    if current_streak >= self.class::COMBO_THRESHOLD
      gained += self.class::COMBO_BONUS
      result[:combo_bonus] = true
      self.current_streak = 0
    end
    m = streak_multiplier
    gained = (gained * m).round if m > 1.0
    gain_xp(gained)
    update_streak!
    result.merge!(xp_gained: gained, new_level: level, level_up: level > result[:old_level],
                  streak_multiplier: m, daily_streak: daily_streak)
  end

  def apply_incorrect_answer!(result)
    self.current_streak = 0
    self.incorrect_streak = incorrect_streak.to_i + 1
    if incorrect_streak >= self.class::PENALTY_THRESHOLD
      lose_xp(self.class::PENALTY_AMOUNT)
      result[:penalty_applied] = true
      self.incorrect_streak = 0
    end
    save!
  end
end
