class CamerasController < ApplicationController
  def create
    @court = Court.find(params[:court_id])

    if params[:camera_type] == "rtsp"
      rtsp_url = params[:rtsp_url]

      @camera = Camera.new(
        court: @court,
        camera_type: :rtsp,
        camera_uid: SecureRandom.hex(6),
        rtsp_url: rtsp_url
      )

    else
      camera_uid, device_path = params[:camera_info].to_s.split("|")

      @camera = Camera.new(
        court: @court,
        camera_type: :usb,
        camera_uid: camera_uid,
        device_path: device_path
      )
    end

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

