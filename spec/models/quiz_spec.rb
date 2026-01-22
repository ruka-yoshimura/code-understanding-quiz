require 'rails_helper'

RSpec.describe Quiz, type: :model do
  describe 'バリデーションの検証' do
    it '問題(question)が必須であること' do
      quiz = build(:quiz, question: nil)
      expect(quiz).not_to be_valid
    end

    it '正解(answer)が必須であること' do
      quiz = build(:quiz, answer: nil)
      expect(quiz).not_to be_valid
    end

    it '選択肢1(option_1)が必須であること' do
      quiz = build(:quiz, option_1: nil)
      expect(quiz).not_to be_valid
    end

    it '選択肢2(option_2)が必須であること' do
      quiz = build(:quiz, option_2: nil)
      expect(quiz).not_to be_valid
    end

    it '全ての属性が揃っていれば有効であること' do
      quiz = build(:quiz)
      expect(quiz).to be_valid
    end
  end
end
