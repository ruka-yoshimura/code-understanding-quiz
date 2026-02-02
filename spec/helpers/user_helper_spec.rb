# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserHelper, type: :helper do
  describe '#user_title' do
    subject { helper.user_title(user) }

    let(:user) { create(:user, level: level) }

    context 'Lv 1-9' do
      let(:level) { 5 }

      it { is_expected.to eq 'ビギナー' }
    end

    context 'Lv 10-19' do
      let(:level) { 15 }

      it { is_expected.to eq '見習いエンジニア' }
    end

    context 'Lv 20-29' do
      let(:level) { 25 }

      it { is_expected.to eq 'コードの探究者' }
    end

    context 'Lv 30-39' do
      let(:level) { 35 }

      it { is_expected.to eq 'コードスペシャリスト' }
    end

    context 'Lv 40-49' do
      let(:level) { 45 }

      it { is_expected.to eq 'コードマスター' }
    end

    context 'Lv 50' do
      let(:level) { 50 }

      it { is_expected.to eq 'レジェンド' }
    end
  end
end
