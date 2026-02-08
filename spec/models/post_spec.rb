# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'アソシエーションの検証' do
    it 'ユーザーに属していること' do
      post = build(:post)
      expect(post.user).to be_present
    end
  end

  describe 'バリデーションの検証' do
    it '有効なファクトリを持つこと' do
      expect(build(:post)).to be_valid
    end

    it 'タイトルが必須であること' do
      post = build(:post, title: nil)
      expect(post).not_to be_valid
    end

    it 'コードの内容が必須であること' do
      post = build(:post, content: nil)
      expect(post).not_to be_valid
    end
  end
end
