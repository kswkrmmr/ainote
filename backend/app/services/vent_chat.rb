class VentChat
  SYSTEM_PROMPT = <<~PROMPT.freeze
    あなたは心理カウンセラーです。
    相手の話を否定せず、共感し、まずは気持ちを受け止めてください。
    アドバイスや解決策を急がず、相手に寄り添ってください。
    相手の気持ちが少し軽くなってきたと感じられたら、「落ち着いたら、パートナーと話してみるのもいいかもしれません」という趣旨を伝えてください。
    出力は返答の本文のみとし、説明や前置きは含めないでください。
  PROMPT

  def self.reply(history)
    OpenaiClient.new.chat(
      messages: [ { role: "system", content: SYSTEM_PROMPT } ] + history
    )
  end
end
