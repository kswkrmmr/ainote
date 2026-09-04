require "rails_helper"

RSpec.describe "Api::Messages", type: :request do
  let(:user) { create(:user) }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }
  let(:room) { create(:room, owner: user) }
  let(:room_member) { create(:room_member, room: room, user: user, partner_display_name: "妻") }
  let(:theme) { create(:theme, room: room, user: user) }

  describe "GET /api/themes/:theme_id/messages" do
    it "returns the messages for the theme in creation order" do
      room_member
      older_message = create(:message, theme: theme, user: user, original_body: "原文1", translated_body: "変換後1", created_at: 1.day.ago)
      newer_message = create(:message, theme: theme, user: user, original_body: "原文2", translated_body: "変換後2")

      get "/api/themes/#{theme.id}/messages", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        [
          { "id" => older_message.id, "user_id" => user.id, "original_body" => "原文1", "translated_body" => "変換後1" },
          { "id" => newer_message.id, "user_id" => user.id, "original_body" => "原文2", "translated_body" => "変換後2" }
        ]
      )
    end

    it "returns not_found for a theme belonging to a room the current user is not a member of" do
      other_theme = create(:theme)

      get "/api/themes/#{other_theme.id}/messages", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns unauthorized without a token" do
      room_member
      get "/api/themes/#{theme.id}/messages"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/themes/:theme_id/messages/preview" do
    before do
      room_member
      allow(MessageTranslator).to receive(:translate).and_return("穏やかな言い回しに変換された文章")
    end

    it "returns the AI-translated text without creating a message" do
      expect {
        post "/api/themes/#{theme.id}/messages/preview", params: { message: { original_body: "なんで私ばっかり家事してるの？" } }, headers: headers
      }.not_to change(Message, :count)

      expect(MessageTranslator).to have_received(:translate).with("なんで私ばっかり家事してるの？", partner_display_name: "妻")
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({ "translated_body" => "穏やかな言い回しに変換された文章" })
    end

    it "returns unprocessable_entity with a blank original_body without calling the AI" do
      post "/api/themes/#{theme.id}/messages/preview", params: { message: { original_body: "" } }, headers: headers

      expect(MessageTranslator).not_to have_received(:translate)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns bad_gateway when the AI translation fails" do
      allow(MessageTranslator).to receive(:translate).and_raise(StandardError, "boom")

      post "/api/themes/#{theme.id}/messages/preview", params: { message: { original_body: "なんで私ばっかり家事してるの？" } }, headers: headers

      expect(response).to have_http_status(:bad_gateway)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns not_found for a theme belonging to a room the current user is not a member of" do
      other_theme = create(:theme)

      post "/api/themes/#{other_theme.id}/messages/preview", params: { message: { original_body: "テスト" } }, headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns unauthorized without a token" do
      post "/api/themes/#{theme.id}/messages/preview", params: { message: { original_body: "テスト" } }

      expect(response).to have_http_status(:unauthorized)
    end

    context "when the OpenAI API call itself fails" do
      around do |example|
        original_key = ENV["OPENAI_API_KEY"]
        ENV["OPENAI_API_KEY"] = "test-api-key"
        example.run
        ENV["OPENAI_API_KEY"] = original_key
      end

      before do
        allow(MessageTranslator).to receive(:translate).and_call_original
      end

      it "returns bad_gateway when the API responds with a rate limit error" do
        stub_request(:post, "https://api.openai.com/v1/chat/completions").to_return(
          status: 429,
          headers: { "Content-Type" => "application/json" },
          body: { error: { message: "Rate limit exceeded", type: "rate_limit_error" } }.to_json
        )

        post "/api/themes/#{theme.id}/messages/preview", params: { message: { original_body: "なんで私ばっかり家事してるの？" } }, headers: headers

        expect(response).to have_http_status(:bad_gateway)
      end

      it "returns bad_gateway when the API times out" do
        stub_request(:post, "https://api.openai.com/v1/chat/completions").to_timeout

        post "/api/themes/#{theme.id}/messages/preview", params: { message: { original_body: "なんで私ばっかり家事してるの？" } }, headers: headers

        expect(response).to have_http_status(:bad_gateway)
      end
    end
  end

  describe "POST /api/themes/:theme_id/messages/check" do
    before do
      room_member
      allow(MessageModerator).to receive(:flagged?).and_return(false)
    end

    it "returns flagged: false when the AI judges the text as not flagged" do
      post "/api/themes/#{theme.id}/messages/check", params: { message: { translated_body: "助かります、ありがとう" } }, headers: headers

      expect(MessageModerator).to have_received(:flagged?).with("助かります、ありがとう")
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({ "flagged" => false })
    end

    it "returns flagged: true when the AI judges the text as flagged" do
      allow(MessageModerator).to receive(:flagged?).and_return(true)

      post "/api/themes/#{theme.id}/messages/check", params: { message: { translated_body: "お前のせいだ" } }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({ "flagged" => true })
    end

    it "returns unprocessable_entity with a blank translated_body without calling the AI" do
      post "/api/themes/#{theme.id}/messages/check", params: { message: { translated_body: "" } }, headers: headers

      expect(MessageModerator).not_to have_received(:flagged?)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns bad_gateway when the AI check fails" do
      allow(MessageModerator).to receive(:flagged?).and_raise(StandardError, "boom")

      post "/api/themes/#{theme.id}/messages/check", params: { message: { translated_body: "お前のせいだ" } }, headers: headers

      expect(response).to have_http_status(:bad_gateway)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns not_found for a theme belonging to a room the current user is not a member of" do
      other_theme = create(:theme)

      post "/api/themes/#{other_theme.id}/messages/check", params: { message: { translated_body: "テスト" } }, headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns unauthorized without a token" do
      post "/api/themes/#{theme.id}/messages/check", params: { message: { translated_body: "テスト" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/themes/:theme_id/messages" do
    before { room_member }

    it "creates a message with the given original and translated text" do
      expect {
        post "/api/themes/#{theme.id}/messages",
          params: { message: { original_body: "なんで私ばっかり家事してるの？", translated_body: "穏やかな言い回しに変換された文章" } },
          headers: headers
      }.to change(Message, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)).to eq(
        {
          "id" => Message.last.id,
          "user_id" => user.id,
          "original_body" => "なんで私ばっかり家事してるの？",
          "translated_body" => "穏やかな言い回しに変換された文章"
        }
      )
    end

    it "broadcasts the created message to the theme's channel" do
      expect {
        post "/api/themes/#{theme.id}/messages",
          params: { message: { original_body: "なんで私ばっかり家事してるの？", translated_body: "穏やかな言い回しに変換された文章" } },
          headers: headers
      }.to have_broadcasted_to(theme).from_channel(MessagesChannel).with { |data|
        expect(data).to eq(
          "id" => Message.last.id,
          "user_id" => user.id,
          "original_body" => "なんで私ばっかり家事してるの？",
          "translated_body" => "穏やかな言い回しに変換された文章"
        )
      }
    end

    it "returns unprocessable_entity with a blank translated_body" do
      expect {
        post "/api/themes/#{theme.id}/messages",
          params: { message: { original_body: "なんで私ばっかり家事してるの？", translated_body: "" } },
          headers: headers
      }.not_to change(Message, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns not_found for a theme belonging to a room the current user is not a member of" do
      other_theme = create(:theme)

      post "/api/themes/#{other_theme.id}/messages",
        params: { message: { original_body: "テスト", translated_body: "テスト" } },
        headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns unauthorized without a token" do
      post "/api/themes/#{theme.id}/messages", params: { message: { original_body: "テスト", translated_body: "テスト" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
