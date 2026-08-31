require "rails_helper"

RSpec.describe OpenaiClient do
  around do |example|
    original_key = ENV["OPENAI_API_KEY"]
    ENV["OPENAI_API_KEY"] = "test-api-key"
    example.run
    ENV["OPENAI_API_KEY"] = original_key
  end

  def stub_chat_completion(model:, content:)
    stub_request(:post, "https://api.openai.com/v1/chat/completions").to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        id: "chatcmpl-123",
        object: "chat.completion",
        created: 1_700_000_000,
        model: model,
        choices: [
          { index: 0, message: { role: "assistant", content: content }, finish_reason: "stop" }
        ]
      }.to_json
    )
  end

  describe "#chat" do
    it "returns the message content from a successful response" do
      stub_chat_completion(model: OpenaiClient::DEFAULT_MODEL, content: "変換後の文章")

      result = described_class.new.chat(messages: [ { role: "user", content: "hi" } ])

      expect(result).to eq("変換後の文章")
    end

    it "sends the given model and messages in the request body" do
      stub = stub_chat_completion(model: "gpt-4.1-mini", content: "ok").with(
        body: hash_including("model" => "gpt-4.1-mini", "messages" => [ { "role" => "user", "content" => "hi" } ])
      )

      described_class.new.chat(messages: [ { role: "user", content: "hi" } ], model: "gpt-4.1-mini")

      expect(stub).to have_been_requested
    end

    it "sends the given response_format in the request body" do
      stub = stub_chat_completion(model: OpenaiClient::DEFAULT_MODEL, content: '{"ok":true}').with(
        body: hash_including("response_format" => { "type" => "json_object" })
      )

      described_class.new.chat(
        messages: [ { role: "user", content: "hi" } ],
        response_format: { type: "json_object" }
      )

      expect(stub).to have_been_requested
    end

    it "raises a RateLimitError when the API responds with 429" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions").to_return(
        status: 429,
        headers: { "Content-Type" => "application/json" },
        body: { error: { message: "Rate limit exceeded", type: "rate_limit_error" } }.to_json
      )

      expect {
        described_class.new.chat(messages: [ { role: "user", content: "hi" } ])
      }.to raise_error(OpenAI::Errors::RateLimitError)
    end

    it "raises an InternalServerError when the API responds with 500" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions").to_return(
        status: 500,
        headers: { "Content-Type" => "application/json" },
        body: { error: { message: "Internal server error", type: "server_error" } }.to_json
      )

      expect {
        described_class.new.chat(messages: [ { role: "user", content: "hi" } ])
      }.to raise_error(OpenAI::Errors::InternalServerError)
    end

    it "raises an APITimeoutError when the request times out" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions").to_timeout

      expect {
        described_class.new.chat(messages: [ { role: "user", content: "hi" } ])
      }.to raise_error(OpenAI::Errors::APITimeoutError)
    end
  end
end
