class MessageModerator
  SYSTEM_PROMPT = <<~PROMPT.freeze
    あなたは文章の内容を確認するモデレーターです。
    入力された文章に、相手を罵る言葉や暴言、著しく攻撃的な表現が含まれているかどうかを判定してください。
    出力は次のJSON形式のみとし、説明や前置きは含めないでください。
    { "flagged": true または false }
  PROMPT

  def self.flagged?(text)
    content = OpenaiClient.new.chat(
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: text }
      ],
      response_format: { type: "json_object" }
    )

    JSON.parse(content)["flagged"]
  end
end
