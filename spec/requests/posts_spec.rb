# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '投稿の削除機能', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let!(:user_post) { create(:post, user: user) }
  let(:other_post) { create(:post, user: other_user) }
  let!(:quiz) { create(:quiz, post: user_post) }

  before { sign_in user }

  describe 'DELETE /posts/:id' do
    context '自分の投稿を削除する場合' do
      it '投稿が削除され、関連するクイズも削除されること' do
        expect do
          delete post_path(user_post)
        end.to change(Post, :count).by(-1).and change(Quiz, :count).by(-1)

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq 'コードを削除しました。'
      end
    end

    context '他人の投稿を削除しようとする場合' do
      it '404エラー（RecordNotFound）が発生すること' do
        sign_out user
        sign_in other_user
        delete post_path(user_post)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
