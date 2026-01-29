# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PostsController, type: :controller do
  let(:user) { create(:user) }
  let(:post_record) { create(:post, user: user) }

  describe 'GET #show' do
    it '認証なしでもアクセスできること' do
      get :show, params: { id: post_record.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:post)).to eq(post_record)
    end
  end

  describe 'GET #new' do
    context 'ログインしている場合' do
      before { sign_in user }

      it '新規投稿フォームが表示されること' do
        get :new
        expect(response).to have_http_status(:success)
        expect(assigns(:post)).to be_a_new(Post)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST #create' do
    context 'ログインしている場合' do
      before { sign_in user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          { post: { title: 'テストタイトル', content: 'puts "hello"' } }
        end

        it '投稿が作成されること' do
          expect do
            post :create, params: valid_params
          end.to change(Post, :count).by(1)
        end

        it '作成された投稿にリダイレクトされること' do
          post :create, params: valid_params
          expect(response).to redirect_to(Post.last)
          expect(flash[:notice]).to eq('コードを投稿しました！')
        end

        it '投稿が現在のユーザーに紐付けられること' do
          post :create, params: valid_params
          expect(Post.last.user).to eq(user)
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          { post: { title: '', content: '' } }
        end

        it '投稿が作成されないこと' do
          expect do
            post :create, params: invalid_params
          end.not_to change(Post, :count)
        end

        it 'newテンプレートが再表示されること' do
          post :create, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:new)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post :create, params: { post: { title: 'test', content: 'test' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
