# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReviewsController, type: :controller do
  let(:user) { create(:user) }
  let(:quiz) { create(:quiz) }

  before { sign_in user }

  describe 'GET #index' do
    context '苦手な問題がある場合' do
      before do
        # 1回間違える
        create(:quiz_answer, user: user, quiz: quiz, correct: false)
      end

      it '苦手リストにクイズが含まれること' do
        get :index
        expect(assigns(:quizzes)).to include(quiz)
      end

      it '正解した後はリストから消えること' do
        # 正解を記録
        create(:quiz_answer, user: user, quiz: quiz, correct: true)
        get :index
        expect(assigns(:quizzes)).not_to include(quiz)
      end
    end

    context '苦手な問題がない場合' do
      it 'リストが空であること' do
        get :index
        expect(assigns(:quizzes)).to be_empty
      end
    end
  end
end
