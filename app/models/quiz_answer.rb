# frozen_string_literal: true

class QuizAnswer < ApplicationRecord
  belongs_to :user
  belongs_to :quiz
end
