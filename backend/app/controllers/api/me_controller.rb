module Api
  class MeController < ApplicationController
    before_action :authenticate_user!

    OPTIONAL_BLANK_KEYS = %i[email password password_confirmation].freeze

    def show
      render json: me_json(current_user)
    end

    def update
      if changing_sensitive_fields? && !current_user.authenticate(params[:current_password])
        render json: { errors: [ "現在のパスワードが正しくありません" ] }, status: :unprocessable_entity
        return
      end

      current_user.avatar.purge if remove_avatar? && !params[:avatar]

      if current_user.update(me_params)
        render json: me_json(current_user)
      else
        render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def changing_sensitive_fields?
      params[:email].present? || params[:password].present?
    end

    def remove_avatar?
      ActiveModel::Type::Boolean.new.cast(params[:remove_avatar])
    end

    def me_json(user)
      {
        id: user.id,
        nickname: user.nickname,
        email: user.email,
        avatar_url: user.avatar.attached? ? rails_blob_url(user.avatar, host: request.base_url) : nil
      }
    end

    def me_params
      params.permit(:nickname, :avatar, :email, :password, :password_confirmation).to_h.reject do |key, value|
        OPTIONAL_BLANK_KEYS.include?(key.to_sym) && value.blank?
      end
    end
  end
end
