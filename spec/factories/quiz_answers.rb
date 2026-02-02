# frozen_string_literal: true

FactoryBot.define do
  factory :quiz_answer do
    user { nil }
    quiz { nil }
    correct { false }
  end
end
