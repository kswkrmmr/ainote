class CreateLineAccountLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :line_account_links do |t|
      t.references :user, null: false, foreign_key: true
      t.string :nonce, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end
    add_index :line_account_links, :nonce, unique: true
  end
end
