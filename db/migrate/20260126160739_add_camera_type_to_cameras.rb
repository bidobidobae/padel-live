class AddCameraTypeToCameras < ActiveRecord::Migration[8.1]
  def change
    add_column :cameras, :camera_type, :string, default: "usb"
    add_column :cameras, :rtsp_url, :string
  end
end
