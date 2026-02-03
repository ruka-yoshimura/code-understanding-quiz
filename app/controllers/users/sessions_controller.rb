# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def guest_sign_in
      user = User.find_by!(email: 'beginner@example.com')
      sign_in user
      redirect_to root_path, notice: 'ゲストユーザーとしてログインしました（初級レベル）。'
    end

    # ログアウト時にデモユーザーのデータをリセット
    def destroy
      current_user.cleanup_demo_data! if user_signed_in? && current_user.demo_user?
      super
    end
  end
end
