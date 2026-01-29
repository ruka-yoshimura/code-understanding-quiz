# frozen_string_literal: true

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
      described_class.where(email: 'guest@example.com').destroy_all
      expect { described_class.guest }.to change(described_class, :count).by(1)
      guest = described_class.last
      expect(guest.email).to eq 'guest@example.com'
    end

    describe '#update_streak!' do
      let(:user) { create(:user, daily_streak: 1, last_answered_date: Date.yesterday) }

      it '昨日回答していればストリークがインクリメントされること' do
        user.update_streak!
        expect(user.daily_streak).to eq 2
        expect(user.last_answered_date).to eq Time.zone.today
      end

      it '今日すでに回答していればストリークは維持されること' do
        user.update(last_answered_date: Time.zone.today)
        expect { user.update_streak! }.not_to change(user, :daily_streak)
      end

      it '1日以上空いていればストリークが1にリセットされること' do
        user.update(last_answered_date: 2.days.ago)
        user.update_streak!
        expect(user.daily_streak).to eq 1
        expect(user.last_answered_date).to eq Time.zone.today
      end
    end

    describe '#gain_xp' do
      let(:user) { create(:user, level: 1, xp: 0) }

      it '経験値が正しく加算されること' do
        expect { user.gain_xp(10) }.to change(user, :xp).by(10)
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

      context 'ストリークボーナスの検証' do
        it '継続1日目( streak < 2 )なら倍率は1.0であること' do
          user.update(daily_streak: 1)
          result = user.answer_quiz(quiz, true)
          # (基本10 + 初見5) * 1.0 = 15
          expect(result[:xp_gained]).to eq 15
        end

        it '継続2日目なら倍率は1.1であること' do
          user.update(daily_streak: 2) # 2日目として設定
          result = user.answer_quiz(quiz, true)
          # (基本10 + 初見5) * 1.1 = 16.5 -> 17
          expect(result[:xp_gained]).to eq 17
          expect(result[:streak_multiplier]).to eq 1.1
        end

        it '継続3日目なら倍率は1.2であること' do
          user.update(daily_streak: 3)
          result = user.answer_quiz(quiz, true)
          # (基本10 + 初見5) * 1.2 = 18.0 -> 18
          expect(result[:xp_gained]).to eq 18
          expect(result[:streak_multiplier]).to eq 1.2
        end

        it '継続6日目以降は1.5倍でキャップされること' do
          user.update(daily_streak: 10)
          result = user.answer_quiz(quiz, true)
          # (基本10 + 初見5) * 1.5 = 22.5 -> 23
          expect(result[:xp_gained]).to eq 23
          expect(result[:streak_multiplier]).to eq 1.5
        end

        it 'コンボボーナスも含めた合計に対して倍率がかかること' do
          # 3連続正解ボーナスで +20
          # streak 3日目で x1.2
          user.update(current_streak: 2, daily_streak: 3)
          result = user.answer_quiz(quiz, true)

          # Base(10) + Combo(20) = 30
          # 30 * 1.2 = 36
          # 初見ボーナス(5)がある場合: (10+5+20)*1.2 = 35*1.2 = 42

          # このテストケースでは初見ボーナスが有効なので 35 * 1.2 = 42
          expect(result[:xp_gained]).to eq 42
        end
      end
    end

    describe '#gain_xp (Level Cap)' do
      let(:user) { create(:user, level: 49, xp: 0) }

      it 'レベル50までは正常にレベルアップすること' do
        # Lv.49 -> Lv.50 には 49 * 50 = 2450 XP 必要
        user.gain_xp(2450)
        expect(user.level).to eq 50
        expect(user.xp).to eq 0
      end

      it 'レベル50に達した後は経験値が増えてもレベルが上がらないこと' do
        user.update(level: 50, xp: 0)
        user.gain_xp(3000)
        expect(user.level).to eq 50
        expect(user.xp).to eq 3000
      end
    end
  end
end
