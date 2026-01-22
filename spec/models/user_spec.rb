require 'rails_helper'

RSpec.describe User, type: :model do
  describe '初期値の検証' do
    let(:user) { create(:user) }

    it 'レベルの初期値が1であること' do
      expect(user.level).to eq 1
    end

    it 'XPの初期値が0であること' do
      expect(user.xp).to eq 0
    end
  end

  describe 'バリデーションの検証' do
    it 'メールアドレスが必須であること' do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
    end

    it '重複したメールアドレスは無効であること' do
      create(:user, email: 'test@example.com')
      user = build(:user, email: 'test@example.com')
      expect(user).not_to be_valid
    end
  end

  describe 'メソッドの検証' do
    it 'ゲストユーザーが作成できること' do
      expect { User.guest }.to change(User, :count).by(1)
      guest = User.last
      expect(guest.email).to eq 'guest@example.com'
    end
  end
end
