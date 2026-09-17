# LINEログインだけで作られたアカウントはメールアドレスとパスワードを持たないため、
# 両方をNULL可にする。メールアドレスのユニーク制約はそのまま残す
# （PostgreSQLはNULL同士を重複として扱わないので、LINE専用アカウントが何件あっても衝突しない）。
class AllowLineOnlyUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :email, true
    change_column_null :users, :password_digest, true
  end
end
