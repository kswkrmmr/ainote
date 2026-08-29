require "rails_helper"

RSpec.describe ConversationSummarizer do
  describe ".summarize" do
    it "sends the conversation as speaker-labeled lines and parses the JSON response" do
      user_a = create(:user, nickname: "たろう")
      user_b = create(:user, nickname: "はなこ")
      theme = create(:theme)
      messages = [
        create(:message, theme: theme, user: user_a, translated_body: "家事の分担について話したいです"),
        create(:message, theme: theme, user: user_b, translated_body: "仕事が忙しく時間が取れていません")
      ]

      client = instance_double(OpenaiClient)
      allow(OpenaiClient).to receive(:new).and_return(client)
      allow(client).to receive(:chat).and_return(
        {
          "participants" => [
            { "name" => "たろう", "points" => [ "家事負担が偏っていると感じている" ] },
            { "name" => "はなこ", "points" => [ "仕事が忙しく時間が取れない" ] }
          ],
          "common_points" => [ "家庭を大切にしたい" ],
          "open_issues" => [ "平日の家事分担" ]
        }.to_json
      )

      result = described_class.summarize(messages)

      expect(client).to have_received(:chat).with(
        messages: [
          { role: "system", content: ConversationSummarizer::SYSTEM_PROMPT },
          { role: "user", content: "たろう: 家事の分担について話したいです\nはなこ: 仕事が忙しく時間が取れていません" }
        ],
        response_format: { type: "json_object" }
      )
      expect(result).to eq(
        {
          "participants" => [
            { "name" => "たろう", "points" => [ "家事負担が偏っていると感じている" ] },
            { "name" => "はなこ", "points" => [ "仕事が忙しく時間が取れない" ] }
          ],
          "common_points" => [ "家庭を大切にしたい" ],
          "open_issues" => [ "平日の家事分担" ]
        }
      )
    end
  end
end
