class AddDevicePathToCameras < ActiveRecord::Migration[8.1]
  def change
    add_column :cameras, :device_path, :string
  end
end
