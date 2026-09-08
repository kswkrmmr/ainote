class OpenaiClient
  DEFAULT_MODEL = "gpt-4o-mini"

  # gemの既定は timeout 600秒 / max_retries 2 で、応答がないと1リクエストが
  # Pumaのスレッドを30分近く占有しうる。このアプリの用途は短いチャット補完なので、
  # 待たされる時間が体感で許容できる範囲に抑える
  REQUEST_TIMEOUT_SECONDS = 30
  MAX_RETRIES = 1

  def initialize
    @client = OpenAI::Client.new(
      api_key: ENV.fetch("OPENAI_API_KEY"),
      timeout: REQUEST_TIMEOUT_SECONDS,
      max_retries: MAX_RETRIES
    )
  end

  def chat(messages:, model: DEFAULT_MODEL, response_format: nil)
    params = { model: model, messages: messages }
    params[:response_format] = response_format if response_format

    response = @client.chat.completions.create(**params)
    response.choices.first.message.content
  end
end
