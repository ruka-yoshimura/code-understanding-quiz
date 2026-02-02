class AddStreakToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :daily_streak, :integer
    add_column :users, :last_answered_date, :date
    add_column :users, :current_streak, :integer
  end
end
