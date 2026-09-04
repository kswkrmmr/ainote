class MessageTranslator
  def self.translate(original_body, partner_display_name:)
    OpenaiClient.new.chat(
      messages: [
        { role: "system", content: system_prompt(partner_display_name) },
        { role: "user", content: original_body }
      ]
    )
  end

  def self.system_prompt(partner_display_name)
    <<~PROMPT
      あなたはパートナー間の対話を支援する通訳です。
      入力された文章は、相手への不満やお願いを伝えたいという気持ちから書かれたものです。
      相手を責める表現を避け、自分の気持ちや要望が伝わりやすい、穏やかで建設的な言い回しに書き換えてください。
      「お前」「あんた」のような強い二人称で相手を呼んでいる場合は、「#{partner_display_name}」という呼び方に置き換えてください。
      元の文章が伝えたい内容(事実・感情・要望)は変えず、言葉遣いだけを調整してください。
      出力は書き換え後の文章のみとし、説明や前置きは含めないでください。
    PROMPT
  end
end
