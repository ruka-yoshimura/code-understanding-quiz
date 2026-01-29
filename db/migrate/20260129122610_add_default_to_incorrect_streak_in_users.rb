# frozen_string_literal: true

class AddDefaultToIncorrectStreakInUsers < ActiveRecord::Migration[7.1]
  def change
    change_column_default :users, :incorrect_streak, 0
    # 既存のNULLデータを0で埋める
    User.where(incorrect_streak: nil).update_all(incorrect_streak: 0)
    change_column_null :users, :incorrect_streak, false, 0
  end
end
