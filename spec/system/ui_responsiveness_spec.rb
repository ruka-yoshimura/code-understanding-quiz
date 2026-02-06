require 'rails_helper'

RSpec.describe '画面表示のレスポンシブ対応', type: :system do
  let(:user) { create(:user, xp: 50, level: 1) }

  before do
    driven_by(:selenium_chrome_headless)
  end

  describe 'ランディングページ（未ログイン）' do
    it 'タイトルがCode / Understanding / Quizの3要素で構成されていること' do
      visit root_path
      expect(page).to have_content('Code')
      expect(page).to have_content('Understanding')
      expect(page).to have_content('Quiz')

      # 構造の確認（スパンで分割されているか）
      expect(page).to have_css('h1 span', text: 'Code')
      expect(page).to have_css('h1 span', text: 'Understanding')
      expect(page).to have_css('h1 span', text: 'Quiz')
    end

    it '主要なアクションボタンが表示されていること' do
      visit root_path
      expect(page).to have_link('新規登録')
      expect(page).to have_link('ログイン')
      expect(page).to have_link('ゲストログインで体験する')
    end
  end

  describe 'ダッシュボード（ログイン後）', :js do
    before do
      sign_in user
      visit root_path
    end

    it 'XP進捗のカラークラス（text-slate-400）が適用されていること' do
      # XP詳細テキストの親要素または自身が slate-400 を持っているか
      expect(page).to have_css('.text-slate-400', text: "(#{user.xp} / #{user.required_xp_for_next_level} XP)")
    end

    it 'マイコード一覧の日付のカラークラス（text-slate-400）が適用されていること' do
      create(:post, user: user)
      visit root_path
      expect(page).to have_css('.text-slate-400', text: Time.current.strftime('%Y/%m/%d'))
    end
  end

  describe '新規投稿ページ' do
    before do
      sign_in user
      visit new_post_path
    end

    it 'タイトルのプレースホルダーが短縮されていること' do
      title_field = find_field('タイトル')
      expect(title_field[:placeholder]).to eq 'プログラムの概要'
    end

    it '投稿ボタンが中央寄せのクラス（justify-center）を持っていること' do
      expect(page).to have_css('button[type="submit"].justify-center')
    end
  end

  describe 'プロフィール編集ページ' do
    before do
      sign_in user
      visit edit_user_registration_path
    end

    it 'パスワード変更セクションの見出しがレスポンシブクラス（flex-col）を持っていること' do
      expect(page).to have_css('h3.flex-col', text: 'パスワードの変更')
    end
  end
end
