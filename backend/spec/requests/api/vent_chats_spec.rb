require "rails_helper"

RSpec.describe "Api::VentChats", type: :request do
  let(:user) { create(:user) }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "POST /api/vent_chats" do
    it "returns the AI reply for the given conversation history" do
      allow(VentChat).to receive(:reply).and_return("それはつらかったですね。")

      post "/api/vent_chats",
        params: { messages: [ { role: "user", content: "もう限界" } ] },
        headers: headers

      expect(VentChat).to have_received(:reply).with([ { role: "user", content: "もう限界" } ])
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({ "reply" => "それはつらかったですね。" })
    end

    it "sends the full conversation history including prior assistant replies" do
      allow(VentChat).to receive(:reply).and_return("そうですよね。")

      history = [
        { role: "user", content: "もう限界" },
        { role: "assistant", content: "つらかったですね。" },
        { role: "user", content: "本当にそう" }
      ]

      post "/api/vent_chats", params: { messages: history }, headers: headers

      expect(VentChat).to have_received(:reply).with(history)
    end

    it "returns unprocessable_entity when the latest message is blank" do
      post "/api/vent_chats",
        params: { messages: [ { role: "user", content: "" } ] },
        headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns unprocessable_entity when no messages are given" do
      post "/api/vent_chats", params: { messages: [] }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns bad_gateway when the AI call fails" do
      allow(VentChat).to receive(:reply).and_raise(StandardError, "boom")

      post "/api/vent_chats",
        params: { messages: [ { role: "user", content: "もう限界" } ] },
        headers: headers

      expect(response).to have_http_status(:bad_gateway)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns unauthorized without a token" do
      post "/api/vent_chats", params: { messages: [ { role: "user", content: "テスト" } ] }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
