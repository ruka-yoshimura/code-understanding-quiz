# frozen_string_literal: true

module Users
  class DemoSessionsController < ApplicationController
    def create
      level = params[:level].to_i
      email = case level
              when 1 then 'beginner@example.com'
              when 29 then 'intermediate@example.com'
              when 49 then 'expert@example.com'
              else
                redirect_to root_path, alert: '無効なデモレベルです。' and return
              end

      user = User.find_by!(email: email)
      sign_in(user)
      redirect_to root_path, notice: "「#{demo_level_name(level)}」としてログインしました。デモを開始してください！"
    end

    private

    def demo_level_name(level)
      case level
      when 1 then '初級レベル (Lv.1)'
      when 29 then '中級レベル (Lv.29)'
      when 49 then '上級レベル (Lv.49)'
      end
    end
  end
end
