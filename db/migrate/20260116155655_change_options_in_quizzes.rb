class ChangeOptionsInQuizzes < ActiveRecord::Migration[7.1]
  def change
    remove_column :quizzes, :options, :json
    add_column :quizzes, :option_1, :string
    add_column :quizzes, :option_2, :string
  end
end
