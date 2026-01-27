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

    cmd = ffmpeg_command(output)
    pid = spawn(*cmd)

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
    if @camera.usb?
      @camera.device_path.present? && File.exist?(@camera.device_path)
    else
      @camera.rtsp_url.present?
    end
  end

  private

  def ffmpeg_command(output)
    input = @camera.input_source

    if @camera.usb?
      [
        "ffmpeg",
        "-y",
        "-f", "v4l2",
        "-framerate", "30",
        "-i", input,
        "-c:v", "libx264",
        "-preset", "veryfast",
        "-pix_fmt", "yuv420p",
        "-movflags", "+frag_keyframe+empty_moov",
        output.to_s
      ]
    else
      [
        "ffmpeg",
        "-y",
        "-rtsp_transport", "tcp",
        "-timeout", "5000000",
        "-fflags", "nobuffer",
        "-i", input,
        "-c:v", "libx264",
        "-preset", "veryfast",
        "-movflags", "+frag_keyframe+empty_moov",
        output.to_s
      ]
    end
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

