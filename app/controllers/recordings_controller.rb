# app/controllers/recordings_controller.rb
class RecordingsController < ApplicationController
  before_action :set_court

  def index
    @recordings = @court.recordings
      .finished
      .includes(:camera)
      .order(created_at: :desc)
  end

  def show
    @recording = @court.recordings.find(params[:id])

    unless File.exist?(Rails.root.join(@recording.file_path))
      return render plain: "File not found", status: 404
    end

    send_file(
      Rails.root.join(@recording.file_path),
      type: "video/mp4",
      disposition: "inline" # penting agar bisa diputar
    )
  end

  private

  def set_court
    @court = Court.find(params[:court_id])
  end
end

