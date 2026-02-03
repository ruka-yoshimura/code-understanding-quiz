# frozen_string_literal: true

# 既存データの削除
Rails.logger.debug 'Cleaning up database...'
QuizAnswer.destroy_all
Quiz.destroy_all
Post.destroy_all
# デモユーザーとシステムユーザーを一旦削除
User.where(email: ['beginner@example.com', 'expert@example.com', 'system@example.com']).destroy_all

# 1. ユーザーの作成
Rails.logger.debug 'Creating users...'
# 初級: Lv.1
beginner = User.create!(email: 'beginner@example.com', password: 'password', level: 1, xp: 40, daily_streak: 1, last_answered_date: Time.zone.today)
# 上級: Lv.49
expert = User.create!(email: 'expert@example.com', password: 'password', level: 49, xp: 2440, daily_streak: 15, last_answered_date: Time.zone.today)
# システムユーザー（公式ドリル用）
system_user = User.create!(email: 'system@example.com', password: 'password', level: 99, xp: 99_999)

# 2. 投稿・クイズデータの生成
Rails.logger.debug 'Generating official drills...'
DemoDataService.create_official_drills(system_user)

Rails.logger.debug 'Generating demo data...'
# 初級・上級ユーザーのデータ
[beginner, expert].each do |user|
  DemoDataService.seed_for(user)
end

Rails.logger.debug 'Database seeding completed successfully!'

Rails.logger.debug 'Database seeding completed successfully!'
