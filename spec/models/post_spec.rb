require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'アソシエーションの検証' do
    it 'ユーザーに属していること' do
      post = build(:post)
      expect(post.user).to be_present
    end
  end

  describe 'バリデーションの検証' do
    # 現在Postモデルにはバリデーションが設定されていないため、後で追加することを検討
    it '有効なファクトリを持つこと' do
      expect(build(:post)).to be_valid
    end
  end
end
