# frozen_string_literal: true

class Quiz < ApplicationRecord
  # どの投稿から生成されたかを管理
  belongs_to :post
  has_many :quiz_answers, dependent: :destroy
  validates :question, presence: true
  validates :answer, presence: true
  validates :option_1, presence: true
  validates :option_2, presence: true
end
