require "rails_helper"

RSpec.describe OpenaiClient do
  around do |example|
    original_key = ENV["OPENAI_API_KEY"]
    ENV["OPENAI_API_KEY"] = "test-api-key"
    example.run
    ENV["OPENAI_API_KEY"] = original_key
  end

  describe "#chat" do
    it "returns the message content from the chat completion response" do
      message = double("message", content: "変換後の文章")
      choice = double("choice", message: message)
      response = double("response", choices: [ choice ])
      completions = double("completions")
      chat = double("chat", completions: completions)
      client = instance_double(OpenAI::Client, chat: chat)
      allow(OpenAI::Client).to receive(:new).and_return(client)

      expect(completions).to receive(:create).with(
        model: OpenaiClient::DEFAULT_MODEL,
        messages: [ { role: "user", content: "hi" } ]
      ).and_return(response)

      result = described_class.new.chat(messages: [ { role: "user", content: "hi" } ])

      expect(result).to eq("変換後の文章")
    end

    it "uses the given model when one is passed" do
      message = double("message", content: "ok")
      choice = double("choice", message: message)
      response = double("response", choices: [ choice ])
      completions = double("completions")
      chat = double("chat", completions: completions)
      client = instance_double(OpenAI::Client, chat: chat)
      allow(OpenAI::Client).to receive(:new).and_return(client)

      expect(completions).to receive(:create).with(
        model: "gpt-4.1-mini",
        messages: [ { role: "user", content: "hi" } ]
      ).and_return(response)

      described_class.new.chat(messages: [ { role: "user", content: "hi" } ], model: "gpt-4.1-mini")
    end
  end
end
