require 'faraday'
require 'json'

class QuizGeneratorService
  BASE_URL = "https://generativelanguage.googleapis.com/v1beta"

  def initialize(code_snippet, existing_questions = [], level = 1)
    @code_snippet = code_snippet
    @existing_questions = existing_questions
    @level = level
    @api_key = ENV['GEMINI_API_KEY']
  end

  def call
    return nil unless @api_key

    model_name = find_model
    return nil unless model_name

    Rails.logger.info "QuizGeneratorService: Using model #{model_name}"

    conn = Faraday.new(url: "#{BASE_URL}/#{model_name}:generateContent")
    response = conn.post do |req|
      req.params['key'] = @api_key
      req.headers['Content-Type'] = 'application/json'
      req.body = request_body.to_json
    end

    if response.status == 200
      parse_response(response.body)
    else
      Rails.logger.error "Gemini API Error: #{response.status} - #{response.body}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "QuizGeneratorService Exception: #{e.message}"
    nil
  end

  private

  def find_model
    conn = Faraday.get("#{BASE_URL}/models?key=#{@api_key}")
    return nil unless conn.status == 200

    models = JSON.parse(conn.body)['models'] || []
    # 特定のアカウントで 2.0-flash-lite が制限されている場合があるためのモデル優先順位
    target = models.find { |m| m['name'].include?('gemini-flash-latest') } ||
             models.find { |m| m['name'].include?('gemini-1.5-flash') } ||
             models.find { |m| m['name'].include?('gemini-flash-lite-latest') } ||
             models.find { |m| m['name'] == 'models/gemini-2.0-flash-lite' } ||
             models.find { |m| m['name'].include?('flash') } ||
             models.find { |m| m['name'].include?('gemini') }

    target ? target['name'] : nil
  rescue
    # API接続エラー時などは安全にnilを返し、呼び出し元でハンドリングする
    nil
  end

  def request_body
    {
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { responseMimeType: "application/json" }
    }
  end

  def prompt
    <<~TEXT
      あなたはRubyプログラミングの先生です。以下のコードに関する「3択クイズ」を1問作成してください。
      出力は以下のキーを持つJSON形式のみとしてください（Markdownの装飾は不要です）。
      日本語で出力してください。

      # 難易度調整指示:
      #{difficulty_prompt}

      Required JSON keys:
      - question: 問題文 (String)
      - answer: 正解の選択肢 (String)
      - option_1: 不正解の選択肢1 (String)
      - option_2: 不正解の選択肢2 (String)
      - explanation: 解説 (String)

      Target Code:
      #{@code_snippet}

      #{avoid_questions_text}
    TEXT
  end

  def difficulty_prompt
    case @level
    when 1..10
      "【初級者向け】
      変数、条件分岐（if/else）、基本的な算術演算など、コードの読み書きの第一歩となる問題にしてください。一目で処理の目的がわかる単純な構造を意識してください。"
    when 11..20
      "【中級者向け】
      配列や連想配列（ハッシュ）の操作、繰り返し処理、関数の定義と引数の受け渡しなど、データの流れを追う必要がある問題にしてください。"
    when 21..30
      "【上級者向け】
      クラスやオブジェクトの利用、例外処理、名前空間、非同期処理の入り口など、複数の要素が組み合わさった「少し複雑な構造」の問題にしてください。エッジケース（特殊な条件下での挙動）も歓迎します。"
    else
      "【エキスパート向け】
      メモリ効率、スコープの境界、高階関数（関数を引数にとる関数）、またはその言語特有の高度な挙動（メタプログラミングやクロージャ等）に関する、深い洞察が必要な問題にしてください。"
    end
  end

  def avoid_questions_text
    return "" if @existing_questions.empty?

    "重要：以下の問題とは異なる、新しい視点のクイズを作成してください：\n" +
    @existing_questions.map { |q| "- #{q}" }.join("\n")
  end

  def parse_response(body)
    json = JSON.parse(body)
    # Geminiのレスポンスからテキスト部分（JSON文字列）を抽出してハッシュに変換
    text = json.dig('candidates', 0, 'content', 'parts', 0, 'text')
    JSON.parse(text)
  end
end
