class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :name
      t.string :rules
      t.boolean :invitation_only
      t.string :password
      t.integer :state, :default => 0

      t.timestamps null: false
    end
  end
end
