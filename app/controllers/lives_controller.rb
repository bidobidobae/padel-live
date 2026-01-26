# app/controllers/lives_controller.rb
class LivesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    @court = Court.find(params[:id])
    @score = read_score(@court)
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

    score = read_score(@court)

    # JANGAN START LAGI JIKA MASIH STARTED
    if score[:started]
      Rails.logger.info "START ignored (already started) for court #{@court.id}"
      return head :ok
    end

    # ===== RESET STATE MATCH BARU =====
    score = ScoreState.default_for(@court)
    score[:started] = true

    write_score(@court.id, score)

    # ===== START RECORDING =====
    @court.cameras.each do |camera|
      rec = Recording.create!(
        court: @court,
        camera: camera,
        active: true
      )

      recorder = CameraRecorder.new(rec)
      recorder.start! if recorder.camera_available?

    end

    @score = score
    broadcast_score!
    head :ok
  end

  def reset
    @court = Court.find(params[:id])

    @court.recordings.where(active: true).find_each do |rec|
      CameraRecorder.new(rec).stop!
    end

    final_score = read_score(@court)
    save_match_history!(@court, final_score)
    @score = ScoreState.default_for(@court)

    write_score(@court.id, @score)

    broadcast_score!
    head :ok
  end

  def back_to_score
    @court = Court.find(params[:id])
    @score = read_score(@court)

    broadcast_score!
    head :ok
  end

  def with_score_lock(court_id)
    key = "lock:court:#{court_id}"
    return unless Rails.cache.write(key, true, unless_exist: true, expires_in: 2)

    yield
  ensure
    Rails.cache.delete(key)
  end


  private

  def save_match_history!(court, score)
    return if score[:winner].nil?

    match = Match.create!(
      court: court,
      score_mode: court.score_mode,
      side_a: court.side_label(:a),
      side_b: court.side_label(:b),
      winner: score[:winner],
      result: build_result_payload(score, court),
      started_at: score[:started_at],
      finished_at: Time.current
    )

    Turbo::StreamsChannel.broadcast_prepend_to(
      "match_history",
      target: "history_list",
      partial: "matches/match",
      locals: { match: match }
    )
  end

  def build_result_payload(score, court)
    if court.score_mode == "international"
      {
        sets_a: score[:sets_a],
        sets_b: score[:sets_b],
        games_a: score[:games_a],
        games_b: score[:games_b]
      }
    else
      {
        score_a: score[:a],
        score_b: score[:b]
      }
    end
  end


  def change_score(side, delta)
    @court = Court.find(params[:id])

    with_score_lock(@court.id) do
      score = read_score(@court)

      return if !score[:started]
      return if score[:winner].present?

      last_recording = @court.recordings.where(active: true).order(created_at: :desc).first

      score = ScoreEngine.apply(
        score: score,
        court: @court,
        side: side,
        delta: delta
      )

      write_score(@court.id, score)

      @court.recordings.where(active: true).each do |rec|
        CameraRecorder.new(rec).stop!
      end

      sleep 0.15

      if score[:winner].nil?
        @court.cameras.each do |camera|
          rec = Recording.create!(court: @court, camera: camera, active: true)
          recorder = CameraRecorder.new(rec)
          recorder.start! if recorder.camera_available?
        end
      end

      @score = score

      if score[:winner].present? && last_recording&.file_path.present?
        broadcast_replay!(last_recording)
      else
        broadcast_score!
      end
    end

    head :ok
  end

  def score_key(court_id)
    "court:#{court_id}:score"
  end

  def read_score(court)
    score = Rails.cache.read(score_key(court.id))

    return score if score.present?

    # hanya fallback kalau benar-benar kosong (fresh court)
    new_score = ScoreState.default_for(court)
    Rails.cache.write(score_key(court.id), new_score)

    new_score
  end


  def write_score(court_id, score)
    Rails.cache.write(score_key(court_id), score)
  end

  def broadcast_score!
    Turbo::StreamsChannel.broadcast_replace_to(
      "court_#{@court.id}",
      target: "score",
      partial: "lives/score",
      locals: { score: @score, court: @court }
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

