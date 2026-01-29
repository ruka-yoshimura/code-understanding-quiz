require 'rails_helper'

RSpec.describe "UserFlows", type: :request do
  let(:user) { create(:user, password: 'password123', password_confirmation: 'password123') }

  describe "メインユーザーフローの検証" do
    it "ログインからクイズ回答まで一通りの操作ができること" do
      # 1. ログイン
      get new_user_session_path
      expect(response).to have_http_status(:success)

      post user_session_path, params: {
        user: {
          email: user.email,
          password: 'password123'
        }
      }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("ログインしました")

      # 2. コードを投稿する
      get new_post_path
      expect(response).to have_http_status(:success)

      post posts_path, params: {
        post: {
          title: "統合テスト用コード",
          content: "def hello_world\n  puts 'hello'\nend"
        }
      }
      expect(response).to redirect_to(Post.last)
      follow_redirect!
      expect(response.body).to include("コードを投稿しました")

      post_record = Post.last

      # 3. クイズを生成する (Serviceをモック)
      quiz_data = {
        'question' => 'hello_worldは何を出力しますか？',
        'answer' => 'hello',
        'option_1' => 'world',
        'option_2' => 'hello world',
        'explanation' => 'putsは引数を出力します。'
      }
      allow_any_instance_of(QuizGeneratorService).to receive(:call).and_return(quiz_data)

      expect {
        post quizzes_path, params: { post_id: post_record.id }
      }.to change(Quiz, :count).by(1)

      expect(response).to redirect_to(Quiz.last)
      follow_redirect!
      expect(response.body).to include("クイズを作成しました")

      quiz_record = Quiz.last

      # 4. クイズに回答する (JSON形式)
      expect {
        post answer_quiz_path(quiz_record), params: { is_correct: 'true' }, as: :json
      }.to change { user.reload.xp }.by_at_least(10)

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['status']).to eq('ok')
      expect(json['xp_gained']).to be > 0

      # 5. 回答履歴が作成されていること
      expect(user.quiz_answers.count).to eq(1)
      expect(user.quiz_answers.last.correct).to be true
    end
  end
end
