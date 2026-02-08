# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '投稿の削除機能', type: :system do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let!(:post_record) { create(:post, user: user, title: '削除対象のコード') }

  before do
    driven_by(:selenium_chrome_headless)
    sign_in user
  end

  it '詳細画面から投稿を削除できること' do
    visit post_path(post_record)

    accept_confirm do
      click_button '投稿を削除'
    end

    expect(page).to have_content 'コードを削除しました。'
    expect(page).not_to have_content '削除対象のコード'
    expect(current_path).to eq root_path
  end

  it 'ホーム画面のカードから投稿を削除できること' do
    # デバッグ: 投稿がユーザーに紐付いているか確認
    expect(post_record.user).to eq user

    visit root_path

    # 正しいユーザーでログインできているか確認
    expect(page).to have_content "こんにちは、#{user.display_name} さん"

    # ページに対象の投稿が表示されるのを十分に待つ（非同期レンダリング対策）
    expect(page).to have_selector("#delete-post-#{post_record.id}", visible: :all, wait: 10)

    # 「削除対象のコード」の削除ボタンをクリック
    accept_confirm do
      find("#delete-post-#{post_record.id}", visible: :all, wait: 10).click
    end

    expect(page).to have_content 'コードを削除しました。'
    expect(page).not_to have_content '削除対象のコード'
  end

  context 'デモユーザーの場合' do
    let(:demo_user) do
      User.find_or_create_by!(email: 'beginner@example.com') do |u|
        u.password = 'password'
        u.level = 1
        u.xp = 0
      end
    end
    let!(:demo_post) { create(:post, user: demo_user, title: 'デモ投稿') }

    before do
      sign_out user
      sign_in demo_user
    end

    it '詳細画面に削除ボタンが表示されないこと' do
      visit post_path(demo_post)
      expect(page).not_to have_button '投稿を削除'
    end

    it 'ホーム画面に削除ボタンが表示されないこと' do
      visit root_path
      # ページに対象の投稿が表示されるのを十分に待つ
      expect(page).to have_content 'デモ投稿'

      # 削除ボタン（ゴミ箱）が存在しないことを確認
      within('.glass', text: 'デモ投稿') do
        expect(page).not_to have_selector('button[title="投稿を削除する"]')
      end
    end
  end
end
