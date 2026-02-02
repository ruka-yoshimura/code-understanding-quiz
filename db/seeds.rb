# frozen_string_literal: true

# 既存データの削除
Rails.logger.debug 'Cleaning up database...'
QuizAnswer.destroy_all
Quiz.destroy_all
Post.destroy_all
User.where(email: ['intermediate@example.com', 'beginner@example.com', 'expert@example.com', 'system@example.com']).destroy_all

# 共通ヘルパー: 投稿作成
def create_post(user, title, code)
  Post.create!(user: user, title: title, content: code)
end

# 1. デモ用ユーザーの作成
Rails.logger.debug 'Creating demo users...'
guest = User.create!(email: 'intermediate@example.com', password: 'password', level: 29, xp: 1440, daily_streak: 5, last_answered_date: Time.zone.today)
beginner = User.create!(email: 'beginner@example.com', password: 'password', level: 1, xp: 40, daily_streak: 1, last_answered_date: Time.zone.today)
expert = User.create!(email: 'expert@example.com', password: 'password', level: 49, xp: 2440, daily_streak: 15, last_answered_date: Time.zone.today)

# 2. システムユーザー（推奨コンテンツ用）の作成
system_user = User.create!(email: 'system@example.com', password: 'password', level: 99, xp: 99_999, daily_streak: 365, last_answered_date: Time.zone.today)

# 投稿データ定義
beginner_posts = [
  { title: '変数展開', code: 'name = "Ruby"; puts "Hello, #{name}!"', quiz: {
    question: 'このコードの出力結果は何ですか？', answer: '"Hello, Ruby!"', option_1: '"Hello, #{name}!"', option_2: 'Error', explanation: ' を使うと文字列の中で変数を展開できます。'
  } },
  { title: '配列の操作', code: 'arr = [1, 2]; arr << 3; p arr', quiz: {
    question: 'arr の最終的な中身はどうなりますか？', answer: '[1, 2, 3]', option_1: '[1, 2]', option_2: '[3, 1, 2]', explanation: '<< 演算子は配列の末尾に要素を追加します。'
  } },
  { title: '文字列と数値', code: 'puts "Ruby" + 3.to_s', quiz: {
    question: 'このコードの実行結果は？', answer: '"Ruby3"', option_1: 'Error', option_2: '"Ruby"', explanation: '数値は .to_s で文字列に変換してから結合する必要があります。'
  } },
  { title: '条件分岐', code: 'status = true; puts status ? "OK" : "NG"', quiz: {
    question: 'このコードの出力は？', answer: '"OK"', option_1: '"NG"', option_2: 'true', explanation: '三項演算子（条件 ? 真 : 偽）を使用しています。'
  } }
]

guest_posts = [
  { title: 'ハッシュの共有', code: 'h = Hash.new([]); h[:a] << 1; h[:b]', quiz: {
    question: 'このコードを実行したとき、h[:b] の値はどうなりますか？', answer: '[1]', option_1: '[]', option_2: 'nil',
    explanation: 'Hash.new([]) は全てのキーで同じデフォルト配列を共有するため、[:a]への変更が[:b]にも影響します。'
  } },
  { title: 'シンボルの同一性', code: 'p :ruby.object_id == :ruby.object_id', quiz: {
    question: 'この比較の結果はどうなりますか？', answer: 'true', option_1: 'false', option_2: 'nil', explanation: 'シンボルは同じ名前であれば必ず同じオブジェクトになります。'
  } },
  { title: 'nilガード', code: 'x = nil; x ||= "Ruby"; p x', quiz: {
    question: 'このコードの出力結果は何ですか？', answer: '"Ruby"', option_1: 'nil', option_2: 'false', explanation: '||= は左辺が nil の場合に右辺を代入します。'
  } },
  { title: 'mapメソッド', code: 'nums = [1, 2, 3]; res = nums.map { |n| n * 2 }; p res', quiz: {
    question: 'res の内容はどのようになりますか？', answer: '[2, 4, 6]', option_1: '[1, 2, 3]', option_2: '[2, 2, 2]', explanation: 'map は各要素に対してブロックを適用し、その結果を新しい配列として返します。'
  } }
]

expert_posts = [
  { title: '制御構造の違い', code: 'def test; l = lambda { return 1 }; l.call; return 2; end; p test', quiz: {
    question: 'このメソッドの戻り値は何ですか？', answer: '2', option_1: '1', option_2: 'nil', explanation: 'lambda内のreturnはlambda自体を抜けるだけで、メソッドからは抜けません。'
  } },
  { title: '定数の探索', code: 'module M; X = 1; end; class C; include M; X = 2; end; p C::X', quiz: {
    question: 'C::X の値は何ですか？', answer: '2', option_1: '1', option_2: 'Error', explanation: 'クラス自身の定数がインクルードしたモジュールの定数より優先されます。'
  } },
  { title: '動的メソッド', code: 'class A; def method_missing(m, *args); m.to_s; end; end; p A.new.hello', quiz: {
    question: 'A.new.hello の実行結果は？', answer: '"hello"', option_1: 'NoMethodError', option_2: 'nil',
    explanation: 'method_missing は定義されていないメソッドが呼ばれたときに実行され、メソッド名を引数として受け取ります。'
  } },
  { title: '特異クラスの参照', code: 'obj = Object.new; class << obj; def hi; "hi"; end; end; p obj.hi', quiz: {
    question: 'obj.hi の実行結果は？', answer: '"hi"', option_1: 'NoMethodError', option_2: 'nil', explanation: 'class << obj 構文を使うことで、特定のオブジェクト（特異クラス）にメソッドを定義できます。'
  } }
]

# 3. 投稿作成ループ
Rails.logger.debug 'Generating posts...'

# 初級者用（投稿のみ）
beginner_posts.each { |data| create_post(beginner, data[:title], data[:code]) }
# ゲスト（中級）用（投稿のみ）
guest_posts.each { |data| create_post(guest, data[:title], data[:code]) }
# 上級者用（投稿のみ）
expert_posts.each { |data| create_post(expert, data[:title], data[:code]) }

# システムユーザー用（投稿 + 全てにバックアップクイズを作成）
# ※ ここでは全レベルのコンテンツを推奨問題として登録します
[beginner_posts, guest_posts, expert_posts].flatten.each do |data|
  post = Post.create!(user: system_user, title: data[:title], content: data[:code], created_at: Time.current)

  # クイズデータがある場合は作成、ない場合は簡易的なものを生成（確実なバックアップのため）
  q_data = data[:quiz] || {
    question: 'このコードの実行結果や挙動として正しいものは？',
    answer: '正しい挙動',
    option_1: '誤った挙動',
    option_2: 'エラー',
    explanation: 'この問題は推奨問題としてシステムにより自動生成されたバックアップです。'
  }

  Quiz.create!(
    post: post,
    original_code: data[:code],
    question: q_data[:question],
    answer: q_data[:answer],
    option_1: q_data[:option_1],
    option_2: q_data[:option_2],
    explanation: q_data[:explanation]
  )
end

# 4. 間違えた問題データの作成（各デモユーザー用）
Rails.logger.debug 'Creating incorrect answers for demo users...'

# 初級ユーザー用: 初級問題から2つ
beginner_quizzes = Quiz.joins(:post).where(posts: { user: system_user, title: %w[変数展開 配列の操作] }).limit(2)
beginner_quizzes.each do |quiz|
  QuizAnswer.create!(user: beginner, quiz: quiz, correct: false, created_at: Time.current)
end

# ゲスト（中級）ユーザー用: 中級問題から2つ（タイトル重複を避けるため明示指定）
guest_quizzes = Quiz.joins(:post).where(posts: { user: system_user, title: %w[ハッシュの共有 シンボルの同一性] }).limit(2)
guest_quizzes.each do |quiz|
  QuizAnswer.create!(user: guest, quiz: quiz, correct: false, created_at: Time.current)
end

# 上級ユーザー用: 上級問題から2つ
expert_quizzes = Quiz.joins(:post).where(posts: { user: system_user, title: %w[制御構造の違い 定数の探索] }).limit(2)
expert_quizzes.each do |quiz|
  QuizAnswer.create!(user: expert, quiz: quiz, correct: false, created_at: Time.current)
end

Rails.logger.debug 'Database seeding completed successfully!'
