class AddQuizGenerationLimitToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :daily_quiz_generation_count, :integer, default: 0, null: false
    add_column :users, :last_quiz_generated_at, :datetime
  end
end
