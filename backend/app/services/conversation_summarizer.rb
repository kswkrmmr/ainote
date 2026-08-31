class ConversationSummarizer
  SYSTEM_PROMPT = <<~PROMPT.freeze
    あなたはパートナー間の話し合いを整理するアシスタントです。
    これまでのやり取りをもとに、発言者ごとの考え、両者の共通点、まだ解決していない論点を抽出してください。
    共通点や論点が見当たらない場合は、空の配列を返してください。
    出力は次のJSON形式のみとし、説明や前置きは含めないでください。
    {
      "participants": [ { "name": "発言者名", "points": [ "考え" ] } ],
      "common_points": [ "共通点" ],
      "open_issues": [ "未解決の論点" ]
    }
  PROMPT

  def self.summarize(messages)
    conversation = messages.map { |message| "#{message.user.nickname}: #{message.translated_body}" }.join("\n")

    content = OpenaiClient.new.chat(
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: conversation }
      ],
      response_format: { type: "json_object" }
    )

    JSON.parse(content)
  end
end
