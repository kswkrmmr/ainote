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

  describe "POST /api/themes/:theme_id/messages" do
    before do
      room_member
      allow(MessageTranslator).to receive(:translate).and_return("穏やかな言い回しに変換された文章")
    end

    it "creates a message using the AI-translated text" do
      expect {
        post "/api/themes/#{theme.id}/messages", params: { message: { original_body: "なんで私ばっかり家事してるの？" } }, headers: headers
      }.to change(Message, :count).by(1)

      expect(MessageTranslator).to have_received(:translate).with("なんで私ばっかり家事してるの？")
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

    it "returns unprocessable_entity with a blank original_body without calling the AI" do
      expect {
        post "/api/themes/#{theme.id}/messages", params: { message: { original_body: "" } }, headers: headers
      }.not_to change(Message, :count)

      expect(MessageTranslator).not_to have_received(:translate)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns bad_gateway when the AI translation fails" do
      allow(MessageTranslator).to receive(:translate).and_raise(StandardError, "boom")

      expect {
        post "/api/themes/#{theme.id}/messages", params: { message: { original_body: "なんで私ばっかり家事してるの？" } }, headers: headers
      }.not_to change(Message, :count)

      expect(response).to have_http_status(:bad_gateway)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns not_found for a theme belonging to a room the current user is not a member of" do
      other_theme = create(:theme)

      post "/api/themes/#{other_theme.id}/messages", params: { message: { original_body: "テスト" } }, headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns unauthorized without a token" do
      post "/api/themes/#{theme.id}/messages", params: { message: { original_body: "テスト" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
