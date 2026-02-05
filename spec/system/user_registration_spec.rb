require 'rails_helper'

RSpec.describe 'UserRegistration', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  it '名前を入力せずに新規登録すると、メールアドレスから自動生成された名前が設定されること' do
    # ユーザー登録ページにアクセス
    visit new_user_registration_path

    # 入力フォームに値を設定
    fill_in 'メールアドレス', with: 'newuser@example.com'
    fill_in 'user_password', with: 'password'
    fill_in 'user_password_confirmation', with: 'password'

    # 名前入力フィールドが存在しないことを確認
    expect(page).not_to have_field '名前'

    # 登録ボタンをクリック
    click_button '新規登録'

    # フラッシュメッセージの確認（「アカウント登録が完了しました」など）
    expect(page).to have_content 'アカウント登録が完了しました'

    # 登録完了後のリダイレクト先（ルート）を確認
    expect(current_path).to eq root_path

    # 自動生成された名前（newuser）が表示されていることを確認
    expect(page).to have_content 'newuser'
  end
end
