class CreateMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :matches do |t|
      t.references :court, null: false, foreign_key: true
      t.string :score_mode
      t.string :side_a
      t.string :side_b
      t.jsonb :result
      t.string :winner
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end
  end
end
