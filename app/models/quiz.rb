class Quiz < ApplicationRecord
  validates :question, presence: true
  validates :answer, presence: true
  validates :option_1, presence: true
  validates :option_2, presence: true
end
