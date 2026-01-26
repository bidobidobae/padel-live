class CreateCourtPlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :court_players do |t|
      t.references :court, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.string :side
      t.integer :position

      t.timestamps
    end
  end
end
