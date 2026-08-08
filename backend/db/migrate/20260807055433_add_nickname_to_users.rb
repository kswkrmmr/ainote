class AddNicknameToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :nickname, :string
    execute "UPDATE users SET nickname = split_part(email, '@', 1) WHERE nickname IS NULL"
    change_column_null :users, :nickname, false
  end

  def down
    remove_column :users, :nickname
  end
end