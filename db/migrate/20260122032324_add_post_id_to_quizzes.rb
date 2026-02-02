class AddPostIdToQuizzes < ActiveRecord::Migration[7.1]
  def change
    add_reference :quizzes, :post, null: false, foreign_key: true
  end
end
