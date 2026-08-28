class MessagesChannel < ApplicationCable::Channel
  def subscribed
    theme = Theme.joins(room: :room_members)
      .where(room_members: { user_id: current_user.id })
      .find_by(id: params[:theme_id])

    if theme
      stream_for theme
    else
      reject
    end
  end
end
