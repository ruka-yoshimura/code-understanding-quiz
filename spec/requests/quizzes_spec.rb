require 'rails_helper'

RSpec.describe 'Quizzes', type: :request do
  let(:user) { create(:user) }
  let(:post_record) { create(:post, user: user) }
  let!(:quiz) { create(:quiz, post: post_record) }

  describe 'GET /quizzes' do
    context 'ログインしている場合' do
      before { sign_in user }

      it 'ステータスコード200が返ること' do
        get quizzes_path
        expect(response).to have_http_status(200)
      end

      it 'クイズ一覧が含まれていること' do
        get quizzes_path
        expect(response.body).to include(quiz.question)
      end
    end

    context 'ログインしていない場合' do
      it 'ログイン画面にリダイレクトされること' do
        get quizzes_path
        expect(response).to have_http_status(302)
        expect(response).to redirect_to new_user_session_path
      end
    end
  end

  describe 'GET /quizzes/:id' do
    context 'ログインしている場合' do
      before { sign_in user }

      it 'クイズ詳細画面が表示されること' do
        get quiz_path(quiz)
        expect(response).to have_http_status(200)
        expect(response.body).to include(quiz.question)
      end
    end
  end

  describe 'POST /quizzes/:id/answer' do
    context 'ログインしている場合' do
      before { sign_in user }

      it '正解時のレスポンスが正常であること (Turbo Stream)' do
        post answer_quiz_path(quiz), params: { is_correct: 'true' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        expect(response).to have_http_status(200)
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
        expect(response.body).to include('turbo-stream')
      end
    end
  end
end
