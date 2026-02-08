# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :ensure_not_demo_user, only: %i[update destroy]

    def update
      super
    end

    def destroy
      super
    end

    protected

    def update_resource(resource, params)
      if params[:password].blank? && params[:password_confirmation].blank?
        # パスワード変更が空の場合は、現在のパスワード等を除外して更新
        resource.update_without_password(params.except(:current_password, :password, :password_confirmation))
      else
        super
      end
    end

    private

    def ensure_not_demo_user
      return unless current_user&.demo_user?

      redirect_to edit_user_registration_path, alert: 'デモユーザーはプロフィールの変更やアカウントの削除ができません。'
    end
  end
end
