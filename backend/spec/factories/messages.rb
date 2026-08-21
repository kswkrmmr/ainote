FactoryBot.define do
  factory :message do
    theme
    user
    original_body { "なんで私ばっかり家事してるの？" }
    translated_body { "家事の負担が偏っているように感じています。一緒に分担を見直せないでしょうか？" }
  end
end
