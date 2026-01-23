class DropClips < ActiveRecord::Migration[8.1]
  def change
    drop_table :clips
  end
end
