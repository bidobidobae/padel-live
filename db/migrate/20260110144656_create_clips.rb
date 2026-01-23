class CreateClips < ActiveRecord::Migration[8.1]
  def change
    create_table :clips do |t|
      t.references :recording, null: false, foreign_key: true
      t.string :side
      t.datetime :from_time
      t.datetime :to_time
      t.string :file_path

      t.timestamps
    end
  end
end
