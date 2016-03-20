class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.references :game, index: true, foreign_key: true
      t.string :name
      t.string :email
      t.string :image_url
      t.references :chaser, foreign_key: true
      t.string :kill_pin

      t.timestamps null: false
    end
  end
end
