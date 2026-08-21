require "rails_helper"

RSpec.describe MessageTranslator do
  describe ".translate" do
    it "sends the system prompt and the original text, returning the AI response" do
      client = instance_double(OpenaiClient)
      allow(OpenaiClient).to receive(:new).and_return(client)
      allow(client).to receive(:chat).and_return("家事の負担が偏っているように感じています。")

      result = described_class.translate("なんで私ばっかり家事してるの？")

      expect(result).to eq("家事の負担が偏っているように感じています。")
      expect(client).to have_received(:chat).with(
        messages: [
          { role: "system", content: MessageTranslator::SYSTEM_PROMPT },
          { role: "user", content: "なんで私ばっかり家事してるの？" }
        ]
      )
    end
  end
end
