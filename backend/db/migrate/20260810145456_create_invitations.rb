class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.references :room, null: false, foreign_key: true
      t.string :token, null: false
      t.datetime :expires_at

      t.timestamps
    end

    add_index :invitations, :token, unique: true
  end
end
