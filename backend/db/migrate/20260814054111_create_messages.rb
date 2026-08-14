class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :theme, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :original_body, null: false
      t.text :translated_body, null: false

      t.timestamps
    end
  end
end
