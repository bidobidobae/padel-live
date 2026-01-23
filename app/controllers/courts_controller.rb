# app/controllers/courts_controller.rb
class CourtsController < ApplicationController
  def index
    @courts = Court.order(:number)
    @available_cameras = CameraDetector.list
  end

  def create
    Court.destroy_all

    params[:total].to_i.times do |i|
      Court.create!(number: i + 1)
    end

    redirect_to courts_path, notice: "Courts berhasil digenerate ulang"
  end
end

