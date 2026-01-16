class CreateQuizzes < ActiveRecord::Migration[7.1]
  def change
    create_table :quizzes do |t|
      t.text :original_code
      t.text :question
      t.string :answer
      t.json :options
      t.text :explanation

      t.timestamps
    end
  end
end
