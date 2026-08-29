module Api
  class ThemesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_room, only: [ :index, :create ]
    before_action :set_theme, only: [ :show, :destroy, :summary ]

    def index
      render json: @room.themes.order(:created_at).map { |theme| theme_json(theme) }
    end

    def show
      render json: { id: @theme.id, title: @theme.title, room_id: @theme.room_id }
    end

    def destroy
      @theme.destroy
      head :no_content
    end

    def summary
      messages = @theme.messages.includes(:user).order(:created_at)

      if messages.empty?
        render json: { errors: [ "まだメッセージがありません" ] }, status: :unprocessable_entity
        return
      end

      result = summarize(messages)
      return if performed?

      render json: result
    end

    def create
      theme = @room.themes.build(theme_params.merge(user: current_user))

      if theme.save
        render json: theme_json(theme), status: :created
      else
        render json: { errors: theme.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def summarize(messages)
      ConversationSummarizer.summarize(messages)
    rescue StandardError
      render json: { errors: [ "AIによる要約に失敗しました。もう一度お試しください。" ] }, status: :bad_gateway
      nil
    end

    def theme_json(theme)
      { id: theme.id, title: theme.title }
    end

    def set_room
      room_member = current_user.room_members.find_by(room_id: params[:room_id])

      if room_member
        @room = room_member.room
      else
        render json: { errors: [ "ルームが見つかりません" ] }, status: :not_found
      end
    end

    def set_theme
      @theme = Theme.joins(room: :room_members)
        .where(room_members: { user_id: current_user.id })
        .find_by(id: params[:id])

      render json: { errors: [ "テーマが見つかりません" ] }, status: :not_found unless @theme
    end

    def theme_params
      params.require(:theme).permit(:title)
    end
  end
end
