require 'rails_helper'

RSpec.describe UsersHelper, type: :helper do
  describe '#user_rank_class' do
    let(:user) { build(:user, xp: 0) }

    context 'レベル1-9の場合（ビギナー）' do
      before { allow(user).to receive(:level).and_return(5) }

      it 'slate系のスタイルクラスを返すこと' do
        expect(helper.user_rank_class(user)).to include('bg-slate-500/20').and include('text-slate-400')
      end
    end

    context 'レベル10-19の場合（見習い）' do
      before { allow(user).to receive(:level).and_return(15) }

      it 'emerald系のスタイルクラスを返すこと' do
        expect(helper.user_rank_class(user)).to include('bg-emerald-500/20').and include('text-emerald-400')
      end
    end

    context 'レベル20-29の場合（探究者）' do
      before { allow(user).to receive(:level).and_return(25) }

      it 'blue系のスタイルクラスを返すこと' do
        expect(helper.user_rank_class(user)).to include('bg-blue-500/20').and include('text-blue-400')
      end
    end

    context 'レベル30-39の場合（スペシャリスト）' do
      before { allow(user).to receive(:level).and_return(35) }

      it 'purple系のスタイルクラスを返すこと' do
        expect(helper.user_rank_class(user)).to include('bg-purple-500/20').and include('text-purple-400')
      end
    end

    context 'レベル40-49の場合（マスター）' do
      before { allow(user).to receive(:level).and_return(45) }

      it 'rose系のスタイルクラスを返すこと' do
        expect(helper.user_rank_class(user)).to include('bg-rose-500/20').and include('text-rose-400')
      end
    end

    context 'レベル50以上の場合（レジェンド）' do
      before { allow(user).to receive(:level).and_return(55) }

      it 'amber系のスタイルクラスを返すこと' do
        expect(helper.user_rank_class(user)).to include('bg-amber-500/20').and include('text-amber-400')
      end
    end

    it '共通のスタイルクラスが含まれていること' do
      expect(helper.user_rank_class(user)).to include('inline-block').and include('rounded-full')
    end
  end
end
