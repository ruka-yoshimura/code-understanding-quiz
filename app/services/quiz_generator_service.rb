require 'faraday'
require 'json'

class QuizGeneratorService
  BASE_URL = "https://generativelanguage.googleapis.com/v1beta"

  def initialize(code_snippet)
    @code_snippet = code_snippet
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
    # Priority: Flash Latest (1.5) -> Pro Latest
    target = models.find { |m| m['name'].include?('gemini-flash-latest') } ||
             models.find { |m| m['name'].include?('gemini-pro-latest') } ||
             models.find { |m| m['name'].include?('gemini') }

    target ? target['name'] : nil
  rescue
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

      Required JSON keys:
      - question: 問題文 (String)
      - answer: 正解の選択肢 (String)
      - option_1: 不正解の選択肢1 (String)
      - option_2: 不正解の選択肢2 (String)
      - explanation: 解説 (String)

      Target Code:
      #{@code_snippet}
    TEXT
  end

  def parse_response(body)
    json = JSON.parse(body)
    # Extract the text content from Gemini's response structure
    text = json.dig('candidates', 0, 'content', 'parts', 0, 'text')

    # Parse the inner JSON string into a Ruby Hash
    JSON.parse(text)
  end
end
