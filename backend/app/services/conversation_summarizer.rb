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

  # display_names は user_id => 表示名。閲覧者から見た呼び方で要約させるために渡す
  def self.summarize(messages, display_names: {})
    conversation = messages.map { |message|
      name = display_names[message.user_id] || message.user.nickname
      "#{name}: #{message.translated_body}"
    }.join("\n")

    content = OpenaiClient.new.chat(
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: conversation }
      ],
      response_format: { type: "json_object" }
    )

    normalize(JSON.parse(content))
  end

  # AIの出力はキーの欠落や型崩れがありうる。画面はこの3つのキーと配列があることを前提に
  # 描画するため、欠けていれば空配列を補い、想定外の型は落としてから返す
  def self.normalize(parsed)
    parsed = {} unless parsed.is_a?(Hash)

    {
      "participants" => normalize_participants(parsed["participants"]),
      "common_points" => normalize_strings(parsed["common_points"]),
      "open_issues" => normalize_strings(parsed["open_issues"])
    }
  end
  private_class_method :normalize

  def self.normalize_participants(participants)
    return [] unless participants.is_a?(Array)

    participants.filter_map do |participant|
      next unless participant.is_a?(Hash)

      name = participant["name"]
      next unless name.is_a?(String) && name.strip.present?

      { "name" => name.strip, "points" => normalize_strings(participant["points"]) }
    end
  end
  private_class_method :normalize_participants

  def self.normalize_strings(values)
    return [] unless values.is_a?(Array)

    values.grep(String).map(&:strip).reject(&:empty?)
  end
  private_class_method :normalize_strings
end
