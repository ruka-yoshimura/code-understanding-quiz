# 既存データの削除（リフレッシュ用）
puts "Cleaning up database..."
QuizAnswer.destroy_all
Quiz.destroy_all
Post.destroy_all
User.where(email: ["user_a@example.com", "user_b@example.com", "user_c@example.com", "guest@example.com"]).destroy_all

# 1. デバッグ用ユーザーの作成
puts "Creating debug users..."

# ユーザーA (Lv.1): 初期状態
user_a = User.create!(
  email: 'user_a@example.com',
  password: 'password',
  level: 1,
  xp: 0,
  daily_streak: 1,
  last_answered_date: Date.today
)

# ユーザーB (Lv.25): 中級・称号「コードの探究者」
# 必要XPを概算で設定
user_b = User.create!(
  email: 'user_b@example.com',
  password: 'password',
  level: 25,
  xp: 500,
  daily_streak: 5,
  last_answered_date: Date.today
)

# ユーザーC (Lv.49): エキスパート・あと少しでレジェンド
user_c = User.create!(
  email: 'user_c@example.com',
  password: 'password',
  level: 49,
  xp: 2400, # 次(Lv50)まであと 49 * 50 = 2450 なので、あと 50 XP
  daily_streak: 10,
  last_answered_date: Date.today
)

# ゲストユーザーも残しておく（次の一問でレベルアップするように調整）
guest_user = User.create!(
  email: 'guest@example.com',
  password: 'password',
  level: 5,
  xp: 240, # Lv.5の必要XPは 5 * 50 = 250 なので、あと 10 XP でレベルアップ
  daily_streak: 1,
  last_answered_date: Date.today
)

puts "Debug users created:"
puts " - User A: Lv 1 (Beginner)"
puts " - User B: Lv 25 (Seeker)"
puts " - User C: Lv 49 (Pro)"

# 2. 「こだわり」のサンプルクイズ（投稿 + クイズ）の作成
puts "Creating curated posts and quizes..."

def create_curated_quiz(user, title, content, quiz_data)
  post = Post.create!(user: user, title: title, content: content)
  Quiz.create!(
    post: post,
    original_code: content,
    question: quiz_data[:question],
    answer: quiz_data[:answer],
    option_1: quiz_data[:option_1],
    option_2: quiz_data[:option_2],
    explanation: quiz_data[:explanation]
  )
end

# 初級: シンプルだが「あれ？」と思うもの
create_curated_quiz(user_a, "数値と文字列の比較", <<~RUBY,
  if 10 == "10"
    puts "Same"
  else
    puts "Different"
  end
RUBY
{
  question: "このコードの出力結果は何ですか？",
  answer: "Different",
  option_1: "Same",
  option_2: "エラーが発生する",
  explanation: "Rubyでは数値の10と文字列の'10'は明確に異なるオブジェクトとして扱われます。自動的な型変換は行われません。"
})

# 中級: 配列と副作用
create_curated_quiz(user_b, "破壊的メソッドの挙動", <<~RUBY,
  arr = [3, 1, 2]
  new_arr = arr.sort!
  new_arr << 4
  p arr
RUBY
{
  question: "最後の `p arr` で表示される内容は何ですか？",
  answer: "[1, 2, 3, 4]",
  option_1: "[3, 1, 2]",
  option_2: "[1, 2, 3]",
  explanation: "sort!は元の配列を破壊的に変更します。また、new_arrは元のarrと同じオブジェクトを参照しているため、new_arrへの追加も元のarrに反映されます。"
})

# 上級: スコープとクロージャ
create_curated_quiz(user_c, "変数のスコープ境界", <<~RUBY,
  def multiplier(n)
    Proc.new { |i| i * n }
  end

  triple = multiplier(3)
  n = 5
  puts triple.call(10)
RUBY
{
  question: "出力される数値は何ですか？",
  answer: "30",
  option_1: "50",
  option_2: "15",
  explanation: "Proc（クロージャ）は定義時のコンテキストの変数 'n' (ここでは3) を保持します。その後の 'n = 5' という再代入は、Proc内部の 'n' には影響を与えません。"
})

# 3. ダッシュボード用データ (回答履歴) の作成
puts "Generating activity history..."

# 過去30日間の学習履歴をユーザーBとCに追加
(0..29).each do |i|
  date = i.days.ago.to_date
  # ユーザーBはたまにサボる
  if i % 3 != 0
    QuizAnswer.create!(
      user: user_b,
      quiz: Quiz.all.sample,
      correct: [true, true, false].sample,
      created_at: date.to_time + 12.hours
    )
  end

  # ユーザーCは皆勤賞に近い
  if i % 7 != 0
    QuizAnswer.create!(
      user: user_c,
      quiz: Quiz.all.sample,
      correct: true,
      created_at: date.to_time + 10.hours
    )
  end
end

# ゲストユーザー用にもサンプルを用意
puts "Creating curated posts for guest user..."

create_curated_quiz(guest_user, "文字列の連結と数値", <<~RUBY,
  a = "10"
  b = 20
  puts a.to_i + b
RUBY
{
  question: "このコードの出力結果は何ですか？",
  answer: "30",
  option_1: "1020",
  option_2: "エラーが発生する",
  explanation: "文字列'10'をto_iメソッドで数値に変換してから足し算しているため、結果は30になります。"
})

create_curated_quiz(guest_user, "配列の基本メソッド", <<~RUBY,
  fruits = ["apple", "banana"]
  fruits.push("cherry")
  puts fruits.length
RUBY
{
  question: "出力される数値（配列の要素数）は何ですか？",
  answer: "3",
  option_1: "2",
  option_2: "4",
  explanation: "pushメソッドで要素を1つ追加したため、要素数は3になります。"
})

create_curated_quiz(guest_user, "シンボルの特徴", <<~RUBY,
  s1 = :ruby
  s2 = :ruby
  puts s1.object_id == s2.object_id
RUBY
{
  question: "出力される結果は何ですか？",
  answer: "true",
  option_1: "false",
  option_2: "エラーが発生する",
  explanation: "シンボルは同じ名前であれば常に同じオブジェクトを参照します(同一のobject_idを持つ)。"
})

puts "Database seeding completed successfully!"
