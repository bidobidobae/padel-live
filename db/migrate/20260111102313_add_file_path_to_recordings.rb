class AddFilePathToRecordings < ActiveRecord::Migration[8.1]
  def change
    add_column :recordings, :file_path, :string
  end
end
