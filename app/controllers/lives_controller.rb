# app/controllers/lives_controller.rb
class LivesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    @court = Court.find(params[:id])
    @score = read_score(@court.id)
  end

  def point_a
    change_score(:a, +1)
  end

  def point_b
    change_score(:b, +1)
  end

  def minus_a
    change_score(:a, -1)
  end

  def minus_b
    change_score(:b, -1)
  end

  def start
    @court = Court.find(params[:id])
    score  = read_score(@court.id)

    # JANGAN START LAGI JIKA MASIH STARTED
    if score[:started]
      Rails.logger.info "START ignored (already started) for court #{@court.id}"
      return head :ok
    end

    # === START RECORDING ===
    @court.cameras.each do |camera|
      rec = Recording.create!(
        court: @court,
        camera: camera,
        active: true
      )

      CameraRecorder.new(rec).start!
    end

    score[:started] = true
    write_score(@court.id, score)

    @score = score
    broadcast_score!
    head :ok
  end


  def reset
    @court = Court.find(params[:id])

    @court.recordings.where(active: true).find_each do |rec|
      CameraRecorder.new(rec).stop!
    end

    @score = { a: 0, b: 0, winner: nil, started: false }
    write_score(@court.id, @score)

    broadcast_score!
    head :ok
  end

  def back_to_score
    @court = Court.find(params[:id])
    @score = read_score(@court.id)

    broadcast_score!
    head :ok
  end

  private

  def change_score(side, delta)
    @court = Court.find(params[:id])
    score  = read_score(@court.id)

    return head :ok unless score[:started]

    return head :ok if score[:winner].present?

    # Update score dulu
    score[side] = [score[side] + delta, 0].max
    total = score[:a] + score[:b]

    if total >= 21
      score[:winner] = score[:a] > score[:b] ? :a : :b
    else
      score[:winner] = nil
    end

    write_score(@court.id, score)

    last_recording = @court.recordings.where(active: true).order(created_at: :desc).first

    if last_recording
      @court.recordings.where(active: true).each do |rec|
        CameraRecorder.new(rec).stop!
      end
    end

    sleep 0.2

    # START recording BARU kalau belum ada winner
    if score[:winner].nil?
      @court.cameras.each do |camera|
        rec = Recording.create!(
          court: @court,
          camera: camera,
          active: true
        )

        CameraRecorder.new(rec).start!
      end
    end

    @score = score

    # broadcast replay ATAU score
    if score[:winner].present? && last_recording&.file_path.present?
      broadcast_replay!(last_recording)
    else
      broadcast_score!
    end
    head :ok
  end


  def score_key(court_id)
    "court:#{court_id}:score"
  end

  def read_score(court_id)
    Rails.cache.fetch(score_key(court_id)) { { a: 0, b: 0, winner: nil, started: false } }
  end

  def write_score(court_id, score)
    Rails.cache.write(score_key(court_id), score)
  end

  def broadcast_score!
    Turbo::StreamsChannel.broadcast_replace_to(
      "court_#{@court.id}",
      target: "score",
      partial: "lives/score",
      locals: { score: @score }
    )
  end

  def broadcast_replay!(recording)
    Turbo::StreamsChannel.broadcast_replace_to(
      "court_#{@court.id}",
      target: "score",
      partial: "lives/replay",
      locals: { recording: recording }
    )
  end

end

