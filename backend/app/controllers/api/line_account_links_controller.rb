module Api
  # あいのてにログインした状態でLINEとの連携を始める・解除する
  class LineAccountLinksController < ApplicationController
    before_action :authenticate_user!

    def create
      link_token = params[:link_token].to_s

      if link_token.blank?
        render json: { errors: [ "連携用の情報が見つかりません。LINEのメッセージからもう一度お試しください。" ] },
               status: :unprocessable_entity
        return
      end

      render json: { redirect_url: LineAccountLinker.start(current_user, link_token) }, status: :created
    end

    # LINEの規約上、連携したユーザーがいつでも解除できるようにする必要がある。
    # ただしLINEログインで作られたアカウントだけは、解除するとログインできなくなるため断る
    def destroy
      if current_user.line_only?
        render json: { errors: [ "LINEでログインしているため、連携を解除できません。解除するとログインできなくなります。" ] },
               status: :unprocessable_entity
        return
      end

      line_user_id = current_user.line_user_id
      current_user.update!(line_user_id: nil)

      # 本人が知らないうちに解除された場合に気づけるよう、解除したLINEに知らせる
      LineAccountLinker.notify_unlinked(line_user_id) if line_user_id.present?

      head :no_content
    end
  end
end
