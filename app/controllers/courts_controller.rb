# app/controllers/courts_controller.rb
class CourtsController < ApplicationController
  def index
    @courts = Court.order(:number)
    @available_cameras = CameraDetector.list
  end

  def create
    Court.destroy_all

    ActiveRecord::Base.connection.reset_pk_sequence!('courts')

    params[:total].to_i.times do |i|
      Court.create!(
        number: i + 1,
        score_mode: "americano",
        score_settings: ScoreConfig.default("americano")
      )

    end

    redirect_to courts_path, notice: "Courts berhasil digenerate ulang"
  end

  def update_score_mode
    @court = Court.find(params[:id])

    return redirect_to courts_path, alert: "Game sedang berjalan" if game_running?(@court)

    new_mode = params[:score_mode]

    if @court.score_mode == new_mode
      settings = @court.score_settings.presence || ScoreConfig.default(new_mode)
    else
      settings = ScoreConfig.default(new_mode)
    end


    @court.update!(
      score_mode: new_mode,
      score_settings: settings
    )

    Rails.cache.delete("court:#{@court.id}:score")

    redirect_to courts_path, notice: "Score mode updated"
  end


  def edit
    @court = Court.find(params[:id])
  end

  def update
    @court = Court.find(params[:id])

    return redirect_to courts_path, alert: "Game sedang berjalan" if game_running?(@court)

    raw = params.require(:court).permit!.to_h

    casted =
      if @court.score_mode == "americano"
        {
          "target" => raw["target"].to_i
        }
      else
        {
          "games_per_set" => raw["games_per_set"].to_i,
          "sets_to_win"   => raw["sets_to_win"].to_i,
          "deuce"         => ActiveModel::Type::Boolean.new.cast(raw["deuce"]),
          "advantage"     => ActiveModel::Type::Boolean.new.cast(raw["advantage"])
        }
      end

    Court.transaction do

      # update score settings
      @court.update!(score_settings: casted)

      # update players assignment
      @court.court_players.destroy_all

      params[:side_a]&.each_with_index do |pid, idx|
        next if pid.blank?

        CourtPlayer.create!(
          court: @court,
          player_id: pid,
          side: "a",
          position: idx + 1
        )
      end

      params[:side_b]&.each_with_index do |pid, idx|
        next if pid.blank?

        CourtPlayer.create!(
          court: @court,
          player_id: pid,
          side: "b",
          position: idx + 1
        )
      end

    end

    Rails.cache.delete("court:#{@court.id}:score")

    redirect_to courts_path, notice: "Court updated successfully"
  end


  private

  def game_running?(court)
    score = Rails.cache.read("court:#{court.id}:score")
    score && score[:started]
  end

end

