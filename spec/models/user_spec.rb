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

    describe '#update_streak!' do
      let(:user) { create(:user, daily_streak: 1, last_answered_date: Date.yesterday) }

      it '昨日回答していればストリークがインクリメントされること' do
        user.update_streak!
        expect(user.daily_streak).to eq 2
        expect(user.last_answered_date).to eq Date.today
      end

      it '今日すでに回答していればストリークは維持されること' do
        user.update(last_answered_date: Date.today)
        expect { user.update_streak! }.not_to change(user, :daily_streak)
      end

      it '1日以上空いていればストリークが1にリセットされること' do
        user.update(last_answered_date: 2.days.ago)
        user.update_streak!
        expect(user.daily_streak).to eq 1
        expect(user.last_answered_date).to eq Date.today
      end
    end

    describe '#gain_xp' do
      let(:user) { create(:user, level: 1, xp: 0) }

      it '経験値が正しく加算されること' do
        expect { user.gain_xp(10) }.to change { user.xp }.by(10)
      end

      it '必要経験値に達するとレベルアップすること' do
        # Lv.1 -> Lv.2 には 50 XP 必要
        user.gain_xp(50)
        expect(user.level).to eq 2
        expect(user.xp).to eq 0
      end

      it '余剰分の経験値が持ち越されること' do
        # 60 XP 獲得 -> 50 XP 消費してレベルアップ、残り 10 XP
        user.gain_xp(60)
        expect(user.level).to eq 2
        expect(user.xp).to eq 10
      end
    end
  end
end
