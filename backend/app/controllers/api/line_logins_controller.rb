module Api
  # LINEログイン。認可URLの払い出しと、コールバック後のログイン処理を行う
  class LineLoginsController < ApplicationController
    def new
      render json: { authorize_url: LineLogin.authorize_url(redirect: params[:redirect]) }
    rescue KeyError, LineLogin::Error => e
      log_and_render_error(e)
    end

    def create
      if params[:code].blank? || params[:state].blank?
        render json: { errors: [ "ログインの情報が不足しています。もう一度お試しください。" ] },
               status: :unprocessable_entity
        return
      end

      result = LineLogin.sign_in(code: params[:code], state: params[:state])
      user = result[:user]

      render json: {
        token: JsonWebToken.encode(user_id: user.id),
        user: { id: user.id, nickname: user.nickname, email: user.email },
        redirect: result[:redirect]
      }, status: :created
    rescue LineLogin::Error => e
      render json: { errors: [ e.message ] }, status: :unauthorized
    rescue KeyError, StandardError => e
      log_and_render_error(e)
    end

    private

    def log_and_render_error(error)
      Rails.logger.error("[LINE] login failed: #{error.class}: #{error.message}")
      render json: { errors: [ "LINEログインに失敗しました。もう一度お試しください。" ] }, status: :bad_gateway
    end
  end
end
