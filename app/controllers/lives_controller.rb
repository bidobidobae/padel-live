# app/controllers/lives_controller.rb
class LivesController < ApplicationController
  layout :resolve_layout
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

  def rollback
    @court = Court.find(params[:id])

    with_score_lock(@court.id) do
      score = read_score(@court)
      return head :ok unless score[:started]

      prev = pop_history(@court.id)
      return head :ok if prev.nil?

      write_score(@court.id, prev)
      @score = prev

      broadcast_score!
    end

    head :ok
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
    reset_history(@court.id)

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

  def history_key(court_id)
    "court:#{court_id}:history"
  end

  def push_history(court_id, score)
    history = Rails.cache.read(history_key(court_id)) || []
    history << Marshal.load(Marshal.dump(score)) # deep clone
    Rails.cache.write(history_key(court_id), history.last(30)) # limit 30 step
  end

  def pop_history(court_id)
    history = Rails.cache.read(history_key(court_id)) || []
    last = history.pop
    Rails.cache.write(history_key(court_id), history)
    last
  end

  def reset_history(court_id)
    Rails.cache.delete(history_key(court_id))
  end

  def change_score(side, delta)
    @court = Court.find(params[:id])

    with_score_lock(@court.id) do
      score = read_score(@court)

      return if !score[:started]
      return if score[:winner].present?

      last_recording = @court.recordings.where(active: true).order(created_at: :desc).first

      push_history(@court.id, score)
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

    def resolve_layout
      action_name == "show" ? "lives" : "application"
    end

end

