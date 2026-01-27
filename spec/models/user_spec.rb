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

    describe '#answer_quiz' do
      let(:user) { create(:user) }
      let(:quiz) { create(:quiz) }

      context '初めて正解する場合' do
        it '通常経験値(10) + ボーナス(5) = 15 XP が付与されること' do
          result = user.answer_quiz(quiz, true)
          expect(result[:xp_gained]).to eq 15
          expect(result[:bonus_applied]).to be true
          expect(user.xp).to eq 15
        end
      end

      context '2回目以降に正解する場合' do
        before { user.quiz_answers.create(quiz: quiz, correct: true) }

        it '通常経験値(10)のみが付与されること' do
          result = user.answer_quiz(quiz, true)
          expect(result[:xp_gained]).to eq 10
          expect(result[:bonus_applied]).to be false
          # 以前の分は考慮せず、今回の増加分を確認
          expect(user.quiz_answers.count).to eq 2
        end
      end

      context 'コンボボーナスの検証' do
        it '正解するとコンボカウントが増えること' do
          user.update(current_streak: 0)
          user.answer_quiz(quiz, true)
          expect(user.current_streak).to eq 1
        end

        it '3連続正解するとボーナス(20XP)が付与されカウントがリセットされること' do
          user.update(current_streak: 2)
          # ベース(10) + コンボ(20) = 30 XP (※初見ボーナスは別途考慮)
          # ここでは初見ボーナスが入るため +5 もある => 合計 35 XP
          result = user.answer_quiz(quiz, true)

          expect(result[:combo_bonus]).to be true
          expect(result[:xp_gained]).to eq 35 # 10 (Base) + 5 (First) + 20 (Combo)
          expect(user.xp).to eq 35
          expect(user.current_streak).to eq 0 # リセット確認
        end

        it '不正解だとコンボカウントがリセットされること' do
          user.update(current_streak: 2)
          user.answer_quiz(quiz, false)
          expect(user.current_streak).to eq 0
        end
      end

      context 'ペナルティの検証' do
        before { user.gain_xp(50) } # テスト用に経験値を付与しておく

        it '不正解だと不正解カウントが増えること' do
          user.update(incorrect_streak: 0)
          user.answer_quiz(quiz, false)
          expect(user.incorrect_streak).to eq 1
        end

        it '3連続不正解するとペナルティ(10XP)が適用されカウントがリセットされること' do
          user.update(incorrect_streak: 2, xp: 50)
          result = user.answer_quiz(quiz, false)

          expect(result[:penalty_applied]).to be true
          expect(user.xp).to eq 40 # 50 - 10
          expect(user.incorrect_streak).to eq 0 # リセット確認
        end

        it '経験値が0未満にはならないこと' do
          user.update(incorrect_streak: 2, xp: 5)
          user.answer_quiz(quiz, false)
          expect(user.xp).to eq 0
        end

        it '正解すると不正解カウントがリセットされること' do
          user.update(incorrect_streak: 2)
          user.answer_quiz(quiz, true)
          expect(user.incorrect_streak).to eq 0
        end
      end
    end
  end
end
