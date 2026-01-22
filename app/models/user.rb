class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :posts, dependent: :destroy
  has_many :quiz_answers, dependent: :destroy

  # 1回の正解で獲得できる経験値
  XP_PER_CORRECT_ANSWER = 10

  # 経験値を獲得し、必要ならレベルアップする
  def gain_xp(amount)
    self.xp += amount

    # レベルアップ判定（ループで複数レベルアップにも対応）
    while xp >= required_xp_for_next_level
      self.xp -= required_xp_for_next_level
      self.level += 1
    end

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
      user.level = 1
      user.xp = 0
    end
  end
end
