# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QuizAnswer, type: :model do
  describe 'Associations' do
    it 'Userに属していること' do
      t = described_class.reflect_on_association(:user)
      expect(t.macro).to eq(:belongs_to)
    end

    it 'Quizに属していること' do
      t = described_class.reflect_on_association(:quiz)
      expect(t.macro).to eq(:belongs_to)
    end
  end

  describe 'Validations' do
    let(:user) { create(:user) }
    let(:quiz) { create(:quiz) }

    it '有効なファクトリを持つこと' do
      answer = described_class.new(user: user, quiz: quiz, correct: true)
      expect(answer).to be_valid
    end
  end
end
