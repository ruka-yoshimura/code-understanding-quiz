# frozen_string_literal: true

class DemoDataService
  def self.seed_for(user)
    new.seed_for(user)
  end

  def seed_for(user)
    case user.email
    when 'beginner@example.com'
      create_demo_data(user)
    when 'expert@example.com'
      create_demo_data(user)
    end
  end

  def seed_analysis(user, titles, system_user)
    # 指定されたタイトルのシステム投稿クイズを取得
    quizzes = Quiz.joins(:post).where(posts: { user: system_user, title: titles })
    quizzes.each_with_index do |quiz, i|
      # 「間違えた問題」として2つ登録
      QuizAnswer.create!(user: user, quiz: quiz, correct: false, created_at: (i + 1).days.ago)
    end
  end

  def self.create_official_drills(system_user)
    service = new
    [
      service.common_posts_data,
      service.extra_official_posts_data
    ].flatten.each do |data|
      service.create_post_with_quiz(system_user, data)
    end
  end

  def create_demo_data(user)
    common_posts_data.each_with_index do |data, i|
      post = create_post_with_quiz(user, data)
      # 全てのクイズに回答履歴を作成（2問正解、2問不正解のバランスにする）
      # ここで i.even? なら正解(true)、奇数なら不正解(false)とする
      QuizAnswer.create!(user: user, quiz: post.quizzes.first, correct: i.even?)
    end
  end

  def create_post_with_quiz(user, data)
    post = Post.create!(user: user, title: data[:title], content: data[:code])
    q_data = data[:quiz]
    Quiz.create!(
      post: post,
      original_code: data[:code],
      question: q_data[:question],
      answer: q_data[:answer],
      option_1: q_data[:option_1],
      option_2: q_data[:option_2],
      explanation: q_data[:explanation]
    )
    post
  end

  def common_posts_data
    [
      { title: '制御構造の違い', code: 'def test; l = lambda { return 1 }; l.call; return 2; end; p test', quiz: {
        question: 'このメソッドの戻り値は何ですか？', answer: '2', option_1: '1', option_2: 'nil', explanation: 'lambda内のreturnはlambda自体を抜けるだけで、メソッドからは抜けません。'
      } },
      { title: '定数の探索', code: 'module M; X = 1; end; class C; include M; X = 2; end; p C::X', quiz: {
        question: 'C::X の値は何ですか？', answer: '2', option_1: '1', option_2: 'Error', explanation: 'クラス自身の定数がインクルードしたモジュールの定数より優先されます。'
      } },
      { title: '動的メソッド', code: 'class A; def method_missing(m, *args); m.to_s; end; end; p A.new.hello', quiz: {
        question: 'A.new.hello の実行結果は？', answer: '"hello"', option_1: 'NoMethodError', option_2: 'nil', explanation: 'method_missing は定義されていないメソッドが呼ばれたときに実行され、メソッド名を引数として受け取ります。'
      } },
      { title: '特異クラスの参照', code: 'obj = Object.new; class << obj; def hi; "hi"; end; end; p obj.hi', quiz: {
        question: 'obj.hi の実行結果は？', answer: '"hi"', option_1: 'NoMethodError', option_2: 'nil', explanation: 'class << obj 構文を使うことで、特定のオブジェクト（特異クラス）にメソッドを定義できます。'
      } }
    ]
  end

  def extra_official_posts_data
    [
      { title: 'ハッシュのデフォルト値', code: 'h = Hash.new("none"); h[:a] = "apple"; p h[:b]', quiz: {
        question: 'h[:b] の値はどうなりますか？', answer: '"none"', option_1: 'nil', option_2: 'Error', explanation: 'Hash.new("none") で設定した値は、存在しないキーを参照した時に返ります。'
      } },
      { title: 'selfの参照', code: 'class MyClass; def what_is_self; self; end; end; p MyClass.new.what_is_self.class', quiz: {
        question: 'このコードの出力結果は何ですか？', answer: 'MyClass', option_1: 'Object', option_2: 'self', explanation: 'インスタンスメソッド内の self はそのインスタンス自身を指します。'
      } }
    ]
  end
end
