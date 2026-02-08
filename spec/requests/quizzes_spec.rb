# frozen_string_literal: true

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

  describe 'POST /posts/:post_id/quizzes' do
    let(:generator_service) { instance_double(QuizGeneratorService) }

    before do
      sign_in user
      allow(QuizGeneratorService).to receive(:new).and_return(generator_service)
    end

    context 'クイズ生成が成功した場合' do
      it 'クイズ詳細画面にリダイレクトされること' do
        allow(generator_service).to receive(:call).and_return({
                                                                'question' => 'テスト問題',
                                                                'answer' => '正解',
                                                                'option_1' => '誤答1',
                                                                'option_2' => '誤答2',
                                                                'explanation' => '解説'
                                                              })

        post quizzes_path(post_id: post_record.id)
        expect(response).to redirect_to(Quiz.last)
        expect(flash[:notice]).to eq('クイズを作成しました！')
      end
    end

    context 'AI生成が失敗した場合（フォールバック）' do
      it '公式ドリルが存在すれば公式ドリル一覧にリダイレクトされること' do
        # システムユーザーと公式投稿を用意
        system_user = User.find_or_create_by!(email: 'system@example.com') do |u|
          u.password = 'password'
          u.level = 99
          u.xp = 0
        end
        create(:post, user: system_user)

        allow(generator_service).to receive_messages(call: nil, error_type: :api_error)

        post quizzes_path(post_id: post_record.id)
        expect(response).to redirect_to(official_posts_path)
        expect(flash[:alert]).to include('AI生成が一時的に利用できません。公式ドリル')
      end

      it '公式ドリルがなければルートパスにリダイレクトされること' do
        # system@example.com のユーザーがいない状態
        User.where(email: 'system@example.com').destroy_all

        allow(generator_service).to receive_messages(call: nil, error_type: :api_error)

        post quizzes_path(post_id: post_record.id)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('AI生成が一時的に利用できません。')
      end
    end

    context '1日の生成上限に達している場合' do
      before do
        user.update!(daily_quiz_generation_count: User::DAILY_QUIZ_LIMIT, last_quiz_generated_at: Time.current)
      end

      it 'クイズが生成されず、公式ドリル一覧にリダイレクトされること' do
        post quizzes_path(post_id: post_record.id)
        expect(response).to redirect_to(official_posts_path)
        expect(flash[:alert]).to include('1日のクイズ生成上限')
      end
    end
  end
end
