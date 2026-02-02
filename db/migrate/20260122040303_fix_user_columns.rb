class FixUserColumns < ActiveRecord::Migration[7.1]
  def change
    # カラムのデフォルト値を設定
    change_column_default :users, :daily_streak, 0
    change_column_default :users, :current_streak, 0
    # 万が一レベルや経験値が消えていた場合の補填（本来はあるはず）
    unless column_exists?(:users, :level)
      add_column :users, :level, :integer, default: 1
    end
    unless column_exists?(:users, :xp)
      add_column :users, :xp, :integer, default: 0
    end
  end
end
