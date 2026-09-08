require "rails_helper"

RSpec.describe ConversationSummarizer do
  describe ".summarize" do
    it "labels each line with the given display name when one is provided" do
      user_a = create(:user, nickname: "たろう")
      user_b = create(:user, nickname: "田中花子")
      theme = create(:theme)
      messages = [
        create(:message, theme: theme, user: user_a, translated_body: "家事の分担について話したいです"),
        create(:message, theme: theme, user: user_b, translated_body: "仕事が忙しく時間が取れていません")
      ]

      client = instance_double(OpenaiClient)
      allow(OpenaiClient).to receive(:new).and_return(client)
      allow(client).to receive(:chat).and_return({ "participants" => [], "common_points" => [], "open_issues" => [] }.to_json)

      described_class.summarize(messages, display_names: { user_b.id => "おかあさん" })

      expect(client).to have_received(:chat).with(
        messages: [
          { role: "system", content: ConversationSummarizer::SYSTEM_PROMPT },
          { role: "user", content: "たろう: 家事の分担について話したいです\nおかあさん: 仕事が忙しく時間が取れていません" }
        ],
        response_format: { type: "json_object" }
      )
    end

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
  describe "AIの応答が想定した形でない場合" do
    def summarize_with(response)
      theme = create(:theme)
      messages = [ create(:message, theme: theme, translated_body: "話したいことがあります") ]

      client = instance_double(OpenaiClient)
      allow(OpenaiClient).to receive(:new).and_return(client)
      allow(client).to receive(:chat).and_return(response)

      described_class.summarize(messages)
    end

    it "fills in empty arrays when keys are missing" do
      expect(summarize_with("{}")).to eq(
        { "participants" => [], "common_points" => [], "open_issues" => [] }
      )
    end

    it "fills in empty arrays when the values are not arrays" do
      response = { "participants" => nil, "common_points" => "なし", "open_issues" => 0 }.to_json

      expect(summarize_with(response)).to eq(
        { "participants" => [], "common_points" => [], "open_issues" => [] }
      )
    end

    it "drops participants without a usable name and non-string points" do
      response = {
        "participants" => [
          { "name" => "たろう", "points" => [ "話し合いたい", nil, 42, "  " ] },
          { "name" => "  ", "points" => [ "名前がないので落とす" ] },
          { "points" => [ "nameキーがないので落とす" ] },
          "文字列なので落とす"
        ],
        "common_points" => [ "家庭を大切にしたい", nil ],
        "open_issues" => []
      }.to_json

      expect(summarize_with(response)).to eq(
        {
          "participants" => [ { "name" => "たろう", "points" => [ "話し合いたい" ] } ],
          "common_points" => [ "家庭を大切にしたい" ],
          "open_issues" => []
        }
      )
    end

    it "supplies points as an empty array when the key is missing" do
      response = { "participants" => [ { "name" => "たろう" } ] }.to_json

      expect(summarize_with(response)["participants"]).to eq(
        [ { "name" => "たろう", "points" => [] } ]
      )
    end
  end
end
