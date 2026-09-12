# ローカル開発ではトンネルのURLが起動ごとに変わるため、LINE側のWebhook URLを
# コマンドで切り替えられるようにする。
# LINE Developersコンソールを手で開かずに済み、設定ミスも起きにくい。
#
#   docker compose logs tunnel                      # 払い出されたURLを確認
#   bin/rails "line:webhook:set[https://xxx.trycloudflare.com]"
#   bin/rails line:webhook:info
#   bin/rails line:webhook:test
namespace :line do
  namespace :webhook do
    WEBHOOK_PATH = "/api/line/webhook".freeze

    desc "LINEのWebhook URLを設定する (例: line:webhook:set[https://xxx.trycloudflare.com])"
    task :set, [ :base_url ] => :environment do |_task, args|
      base_url = args[:base_url].to_s.chomp("/")
      abort "ベースURLを渡してください (例: bin/rails \"line:webhook:set[https://xxx.trycloudflare.com]\")" if base_url.empty?
      abort "httpsのURLを指定してください。LINEはhttpのWebhookを受け付けません。" unless base_url.start_with?("https://")

      endpoint = "#{base_url}#{WEBHOOK_PATH}"
      response = LineWebhookSettings.set(endpoint)

      if response.is_a?(Net::HTTPSuccess)
        puts "設定しました: #{endpoint}"
        puts "続けて `bin/rails line:webhook:test` で疎通を確認できます。"
      else
        abort "設定に失敗しました (#{response.code}): #{response.body}"
      end
    end

    desc "LINEに設定されているWebhook URLを表示する"
    task info: :environment do
      response = LineWebhookSettings.info
      puts "#{response.code}: #{response.body}"
    end

    desc "LINEからWebhookへの疎通テストを行う"
    task test: :environment do
      response = LineWebhookSettings.test
      puts "#{response.code}: #{response.body}"
      puts "success が false の場合、statusCode を見てください。" \
           "403ならRailsのホスト制限、404ならルーティング、000ならトンネルが落ちています。"
    end
  end
end
