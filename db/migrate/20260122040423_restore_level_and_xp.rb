class RestoreLevelAndXp < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:users, :level)
      add_column :users, :level, :integer, default: 1
    end
    unless column_exists?(:users, :xp)
      add_column :users, :xp, :integer, default: 0
    end
    change_column_default :users, :daily_streak, from: nil, to: 0
    change_column_default :users, :current_streak, from: nil, to: 0
  end
end
