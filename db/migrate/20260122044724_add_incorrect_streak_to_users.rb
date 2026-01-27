class AddIncorrectStreakToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :incorrect_streak, :integer
  end
end
