require "rails_helper"

RSpec.describe MessageTranslator do
  describe ".translate" do
    it "sends the system prompt with the partner's display name and the original text, returning the AI response" do
      client = instance_double(OpenaiClient)
      allow(OpenaiClient).to receive(:new).and_return(client)
      allow(client).to receive(:chat).and_return("家事の負担が偏っているように感じています。")

      result = described_class.translate("なんで私ばっかり家事してるの？", partner_display_name: "妻")

      expect(result).to eq("家事の負担が偏っているように感じています。")
      expect(client).to have_received(:chat).with(
        messages: [
          { role: "system", content: MessageTranslator.system_prompt("妻") },
          { role: "user", content: "なんで私ばっかり家事してるの？" }
        ]
      )
    end
  end

  describe ".system_prompt" do
    it "embeds the given partner display name" do
      expect(described_class.system_prompt("妻")).to include("「妻」に置き換えます")
    end

    it "instructs not to add the display name when the original has no word for the partner" do
      expect(described_class.system_prompt("妻")).to include("「妻」を出力に一切含めません")
    end
  end
end
