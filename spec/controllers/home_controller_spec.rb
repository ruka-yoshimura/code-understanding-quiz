# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe 'GET #index' do
    context 'ログインしている場合' do
      let(:user) { create(:user) }
      let!(:user_posts) { create_list(:post, 3, user: user) }
      let!(:other_user_post) { create(:post) }

      before { sign_in user }

      it '正常にページが表示されること' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'ログインユーザーの投稿のみが取得されること' do
        get :index
        expect(assigns(:posts)).to match_array(user_posts)
        expect(assigns(:posts)).not_to include(other_user_post)
      end

      it '投稿が作成日時の降順で取得されること' do
        get :index
        posts = assigns(:posts)
        expect(posts.first.created_at).to be >= posts.last.created_at
      end
    end

    context 'ログインしていない場合' do
      it '正常にランディングページが表示されること' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it '投稿リストが空であること' do
        get :index
        expect(assigns(:posts)).to eq([])
      end
    end
  end
end
