FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    level { 1 }
    xp { 0 }
  end

  factory :post do
    title { Faker::Lorem.sentence(word_count: 3) }
    content { "def hello\n  puts 'world'\nend" }
    association :user
  end

  factory :quiz do
    association :post
    original_code { "def hello\n  puts 'world'\nend" }
    question { 'この実行結果は何ですか？' }
    answer { 'world' }
    option_1 { 'hello' }
    option_2 { 'error' }
    explanation { 'putsメソッドにより標準出力に表示されます。' }
  end
end
