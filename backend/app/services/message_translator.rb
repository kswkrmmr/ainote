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
      相手を責める表現を避け、自分の気持ちや要望が伝わりやすい、穏やかで建設的な言い回しに書き換えてください。
      元の文章が伝えたい内容(事実・感情・要望)は変えず、言葉遣いだけを調整してください。内容を足したり、別の意味にしたりしないでください。

      # 相手の呼び方
      元の文章に「お前」「あんた」「そっち」など相手を指す言葉がある場合は、その語を「#{partner_display_name}」に置き換えます。
      例: 「お前がいつも約束を破る」→「#{partner_display_name}が約束を守れないことがあって、少し残念に感じています」

      元の文章に相手を指す言葉がない場合は、「#{partner_display_name}」を出力に一切含めません。文頭の呼びかけとして付け足すこともしません。
      例: 「今日も一日お疲れ様でした」→「今日も一日お疲れ様でした」
      例: 「洗い物、そのままになってるよ」→「洗い物がそのままになっているのが気になっています」

      # 出力の形式
      出力が複数の文になる場合は、文ごとに改行してください。
      書き換え後の文章のみを出力し、説明や前置きは含めないでください。
    PROMPT
  end
end
