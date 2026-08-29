class OpenaiClient
  DEFAULT_MODEL = "gpt-4o-mini"

  def initialize
    @client = OpenAI::Client.new(api_key: ENV.fetch("OPENAI_API_KEY"))
  end

  def chat(messages:, model: DEFAULT_MODEL, response_format: nil)
    params = { model: model, messages: messages }
    params[:response_format] = response_format if response_format

    response = @client.chat.completions.create(**params)
    response.choices.first.message.content
  end
end
