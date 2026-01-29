# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QuizzesController, type: :controller do
  let(:user) { create(:user) }
  let(:post_record) { create(:post, user: user) }
  let(:quiz) { create(:quiz, post: post_record) }

  before { sign_in user }

  describe 'GET #show' do
    it '正常にクイズページが表示されること' do
      get :show, params: { id: quiz.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:quiz)).to eq(quiz)
    end
  end

  describe 'POST #create' do
    context 'クイズ生成が成功する場合' do
      let(:quiz_data) do
        {
          'question' => 'テスト問題',
          'answer' => '正解',
          'option_1' => '選択肢1',
          'option_2' => '選択肢2',
          'explanation' => '解説'
        }
      end

      before do
        allow_any_instance_of(QuizGeneratorService).to receive(:call).and_return(quiz_data)
      end

      it 'クイズが作成され、クイズページにリダイレクトされること' do
        expect do
          post :create, params: { post_id: post_record.id }
        end.to change(Quiz, :count).by(1)

        expect(response).to redirect_to(Quiz.last)
        expect(flash[:notice]).to eq('クイズを作成しました！')
      end

      it '作成されたクイズに正しいデータが設定されること' do
        post :create, params: { post_id: post_record.id }

        created_quiz = Quiz.last
        expect(created_quiz.question).to eq('テスト問題')
        expect(created_quiz.answer).to eq('正解')
        expect(created_quiz.option_1).to eq('選択肢1')
        expect(created_quiz.option_2).to eq('選択肢2')
        expect(created_quiz.explanation).to eq('解説')
      end
    end

    context 'API レート制限エラーの場合' do
      before do
        service = instance_double(QuizGeneratorService)
        allow(QuizGeneratorService).to receive(:new).and_return(service)
        allow(service).to receive_messages(call: nil, error_type: :rate_limit)
      end

      it '適切なエラーメッセージが表示されること' do
        post :create, params: { post_id: post_record.id }

        expect(response).to redirect_to(post_path(post_record))
        expect(flash[:alert]).to include('APIの利用制限')
      end
    end

    context 'その他のエラーの場合' do
      before do
        service = instance_double(QuizGeneratorService)
        allow(QuizGeneratorService).to receive(:new).and_return(service)
        allow(service).to receive_messages(call: nil, error_type: nil)
      end

      it '一般的なエラーメッセージが表示されること' do
        post :create, params: { post_id: post_record.id }

        expect(response).to redirect_to(post_path(post_record))
        expect(flash[:alert]).to include('クイズ生成に失敗')
      end
    end
  end

  describe 'POST #answer' do
    context '正解の場合' do
      it 'XPが付与されること' do
        expect do
          post :answer, params: { id: quiz.id, is_correct: 'true' }, format: :json
        end.to change { user.reload.xp }.by_at_least(10)
      end

      it '正しいJSONレスポンスが返ること' do
        post :answer, params: { id: quiz.id, is_correct: 'true' }, format: :json

        json_response = response.parsed_body
        expect(json_response['status']).to eq('ok')
        expect(json_response['xp_gained']).to be > 0
        expect(response).to have_http_status(:success)
      end

      it 'QuizAnswerレコードが作成されること' do
        expect do
          post :answer, params: { id: quiz.id, is_correct: 'true' }, format: :json
        end.to change(QuizAnswer, :count).by(1)

        expect(QuizAnswer.last.correct).to be true
      end
    end

    context '不正解の場合' do
      it 'XPが付与されないこと' do
        expect do
          post :answer, params: { id: quiz.id, is_correct: 'false' }, format: :json
        end.not_to(change { user.reload.xp })
      end

      it '正しいJSONレスポンスが返ること' do
        post :answer, params: { id: quiz.id, is_correct: 'false' }, format: :json

        json_response = response.parsed_body
        expect(json_response['status']).to eq('ok')
        expect(json_response['xp_gained']).to eq(0)
      end

      it 'QuizAnswerレコードが作成されること' do
        expect do
          post :answer, params: { id: quiz.id, is_correct: 'false' }, format: :json
        end.to change(QuizAnswer, :count).by(1)

        expect(QuizAnswer.last.correct).to be false
      end
    end

    context 'Turbo Stream形式でのリクエスト' do
      it 'Turbo Streamレスポンスが返ること' do
        post :answer, params: { id: quiz.id, is_correct: 'true' }, format: :turbo_stream

        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
        expect(response).to have_http_status(:success)
      end
    end

    context 'レベルアップの場合' do
      before do
        # レベルアップ直前の状態にする
        user.update(level: 1, xp: 45)
      end

      it 'レベルアップが検出されること' do
        post :answer, params: { id: quiz.id, is_correct: 'true' }, format: :json

        json_response = response.parsed_body
        expect(json_response['level_up']).to be true
        expect(json_response['new_level']).to be > json_response['old_level']
      end
    end
  end

  describe '認証が必要なこと' do
    before { sign_out user }

    it 'ログインしていない場合はリダイレクトされること' do
      get :show, params: { id: quiz.id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
