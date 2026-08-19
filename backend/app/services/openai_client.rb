class OpenaiClient
  DEFAULT_MODEL = "gpt-4o-mini"

  def initialize
    @client = OpenAI::Client.new(api_key: ENV.fetch("OPENAI_API_KEY"))
  end

  def chat(messages:, model: DEFAULT_MODEL)
    response = @client.chat.completions.create(model: model, messages: messages)
    response.choices.first.message.content
  end
end
