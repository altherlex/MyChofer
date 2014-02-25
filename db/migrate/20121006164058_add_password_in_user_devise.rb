class AddPasswordInUserDevise < ActiveRecord::Migration
  def change
		add_column :users, :password, :string 
		add_column :users, :senha, :string
  end
end
