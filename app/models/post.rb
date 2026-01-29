class Post < ApplicationRecord
  belongs_to :user
  # この投稿から生成されたクイズ群
  has_many :quizzes, dependent: :destroy

  validates :title, presence: true
  validates :content, presence: true
end
