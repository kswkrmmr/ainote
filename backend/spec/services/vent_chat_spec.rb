require "rails_helper"

RSpec.describe VentChat do
  describe ".reply" do
    it "sends the system prompt followed by the conversation history" do
      client = instance_double(OpenaiClient)
      allow(OpenaiClient).to receive(:new).and_return(client)
      allow(client).to receive(:chat).and_return("それはつらかったですね。")

      history = [ { role: "user", content: "もう限界" } ]
      result = described_class.reply(history)

      expect(result).to eq("それはつらかったですね。")
      expect(client).to have_received(:chat).with(
        messages: [
          { role: "system", content: VentChat::SYSTEM_PROMPT },
          { role: "user", content: "もう限界" }
        ]
      )
    end
  end
end
