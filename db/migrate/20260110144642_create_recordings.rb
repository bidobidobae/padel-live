class CreateRecordings < ActiveRecord::Migration[8.1]
  def change
    create_table :recordings do |t|
      t.references :court, null: false, foreign_key: true
      t.references :camera, null: false, foreign_key: true
      t.boolean :active, default: true
      t.datetime :started_at
      t.datetime :stopped_at

      t.timestamps
    end
  end
end
