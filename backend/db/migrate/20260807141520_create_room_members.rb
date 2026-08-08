class CreateRoomMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :room_members do |t|
      t.references :room, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :partner_display_name, null: false

      t.timestamps
    end

    add_index :room_members, [ :room_id, :user_id ], unique: true
  end
end
