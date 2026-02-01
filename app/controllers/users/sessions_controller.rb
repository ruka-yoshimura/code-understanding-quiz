# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def guest_sign_in
      user = User.find_by!(email: 'intermediate@example.com')
      sign_in user
      redirect_to root_path, notice: 'ゲストユーザー（中等レベル）としてログインしました。'
    end
  end
end
