# app/services/camera_recorder.rb
class CameraRecorder
  BASE_PATH = Rails.root.join("storage/recordings")

  def initialize(recording)
    @recording = recording
    @camera    = recording.camera
    @court     = recording.court
  end

  # =========================
  # START RECORDING
  # =========================
  def start!
    return unless camera_available?

    FileUtils.mkdir_p(BASE_PATH)

    output = BASE_PATH.join(filename)

    pid = spawn(ffmpeg_command(output))

    Process.detach(pid)

    # simpan hanya jika process benar-benar hidup
    if process_alive?(pid)
      Rails.cache.write(pid_key, pid)

      @recording.update!(
        started_at: Time.current,
        active: true,
        file_path: output.to_s
      )
    else
      Rails.logger.error "FFMPEG failed to start for camera #{@camera.id}"
    end
  rescue => e
    Rails.logger.error "Recorder start error: #{e.message}"
  end

  # =========================
  # STOP RECORDING
  # =========================
  def stop!
    pid = Rails.cache.read(pid_key)
    return unless pid

    begin
      Process.kill("INT", pid)

      wait_process_exit(pid)

    rescue Errno::ESRCH
      Rails.logger.warn "Recorder already stopped (PID #{pid})"
    ensure
      Rails.cache.delete(pid_key)

      @recording.update!(
        stopped_at: Time.current,
        active: false
      )
    end
  rescue => e
    Rails.logger.error "Recorder stop error: #{e.message}"
  end

  # =========================
  # HELPERS
  # =========================

  def camera_available?
    path = @camera.device_path
    path.present? && File.exist?(path)
  end

  private

  def ffmpeg_command(output)
    "ffmpeg -y -f v4l2 -video_size 1920x1080 -i #{@camera.device_path} " \
    "-c:v libx264 -movflags +frag_keyframe+empty_moov #{output}"
  end

  def process_alive?(pid)
    Process.getpgid(pid)
    true
  rescue Errno::ESRCH
    false
  end

  def wait_process_exit(pid)
    Timeout.timeout(2) do
      loop do
        Process.getpgid(pid)
        sleep 0.05
      end
    end
  rescue Errno::ESRCH, Timeout::Error
    # process sudah mati atau timeout aman
  end

  def filename
    "court#{@court.id}_camera#{@camera.id}_#{Time.now.to_i}.mp4"
  end

  def pid_key
    "recording:#{@recording.id}:pid"
  end
end

