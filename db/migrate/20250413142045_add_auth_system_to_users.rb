class AddAuthSystemToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :auth_system, :string
  end
end
