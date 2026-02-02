# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def guest_sign_in
      user = User.find_by!(email: 'intermediate@example.com')
      sign_in user
      redirect_to root_path, notice: 'ゲストユーザー（中等レベル）としてログインしました。'
    end

    # ログアウト時にデモユーザーのデータをリセット
    def destroy
      current_session_user = current_user
      current_session_user.cleanup_demo_data! if current_session_user&.demo_user?
      super
    end
  end
end
