class AddLineNotifiedAtToRoomMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :room_members, :line_notified_at, :datetime
  end
end
