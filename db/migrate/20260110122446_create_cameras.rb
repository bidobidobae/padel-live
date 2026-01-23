class CreateCameras < ActiveRecord::Migration[8.1]
  def change
    create_table :cameras do |t|
      t.references :court, null: false, foreign_key: true
      t.string :camera_uid, null: false
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
