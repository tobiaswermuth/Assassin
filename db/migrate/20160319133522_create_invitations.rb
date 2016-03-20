class CreateInvitations < ActiveRecord::Migration
  def change
    create_table :invitations do |t|
      t.references :game, index: true, foreign_key: true
      t.string :token
      t.string :name

      t.timestamps null: false
    end
  end
end
