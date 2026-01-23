class CamerasController < ApplicationController
  def create
    @court = Court.find(params[:court_id])
    camera_uid, device_path = params[:camera_info].to_s.split("|")
    @camera = Camera.new(
      court: @court,
      camera_uid: camera_uid,   # tetap simpan UID jika ingin identifikasi unik
      device_path: device_path  # ini path yang dipilih user
    )

    if @camera.save
      redirect_to courts_path, notice: "Camera berhasil ditambahkan"
    else
      redirect_to courts_path, alert: @camera.errors.full_messages.to_sentence
    end
  end

  def destroy
    camera = Camera.find(params[:id])
    camera.destroy

    redirect_to courts_path, notice: "Camera dihapus"
  end
end

