# R2の環境変数が欠けていても、バケット名さえあればアプリは起動してしまい、
# 画像をアップロードした時に初めて500になる。原因が分かりにくいので起動時に警告する。
#
# ここで例外を投げないのは、アバターは補助的な機能であり、設定漏れでアプリ全体を
# 止めるほうが損失が大きいため。ログを見れば何が足りないかは分かる。
if Rails.env.production?
  Rails.application.config.after_initialize do
    missing = %w[
      R2_ACCESS_KEY_ID
      R2_SECRET_ACCESS_KEY
      R2_ENDPOINT
      R2_BUCKET
    ].select { |name| ENV[name].blank? }

    if missing.any?
      Rails.logger.error(
        "[R2] 環境変数が設定されていないため、画像のアップロードは失敗します: #{missing.join(", ")}"
      )
    end
  end
end
