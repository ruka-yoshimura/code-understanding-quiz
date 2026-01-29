# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QuizGeneratorService do
  let(:code) { "puts 'hello'" }

  describe '#difficulty_prompt' do
    def service(level)
      QuizGeneratorService.new(code, [], level)
    end

    it 'Lv.1-10なら初級者向けの指示が含まれること' do
      expect(service(5).send(:difficulty_prompt)).to include('初級者向け')
    end

    it 'Lv.11-20なら中級者向けの指示が含まれること' do
      expect(service(15).send(:difficulty_prompt)).to include('中級者向け')
    end

    it 'Lv.21-30なら上級者向けの指示が含まれること' do
      expect(service(25).send(:difficulty_prompt)).to include('上級者向け')
    end

    it 'Lv.31以上ならエキスパート向けの指示が含まれること' do
      expect(service(40).send(:difficulty_prompt)).to include('エキスパート向け')
    end
  end

  describe '#prompt' do
    it '難易度調整指示がプロンプト全体に含まれていること' do
      s = described_class.new(code, [], 10)
      expect(s.send(:prompt)).to include('# 難易度調整指示:')
      expect(s.send(:prompt)).to include('初級者向け')
    end
  end
end
