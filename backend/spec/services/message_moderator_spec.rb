require "rails_helper"

RSpec.describe MessageModerator do
  describe ".flagged?" do
    it "sends the system prompt and the text, returning the parsed flagged value" do
      client = instance_double(OpenaiClient)
      allow(OpenaiClient).to receive(:new).and_return(client)
      allow(client).to receive(:chat).and_return({ "flagged" => true }.to_json)

      result = described_class.flagged?("お前のせいで台無しだ")

      expect(result).to eq(true)
      expect(client).to have_received(:chat).with(
        messages: [
          { role: "system", content: MessageModerator::SYSTEM_PROMPT },
          { role: "user", content: "お前のせいで台無しだ" }
        ],
        response_format: { type: "json_object" }
      )
    end

    it "returns false when the AI judges the text as not flagged" do
      client = instance_double(OpenaiClient)
      allow(OpenaiClient).to receive(:new).and_return(client)
      allow(client).to receive(:chat).and_return({ "flagged" => false }.to_json)

      expect(described_class.flagged?("助かります、ありがとう")).to eq(false)
    end
  end
end
