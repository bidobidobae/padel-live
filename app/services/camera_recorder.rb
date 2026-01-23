# app/services/camera_recorder.rb
class CameraRecorder
  BASE_PATH = Rails.root.join("storage/recordings")

  def initialize(recording)
    @recording = recording
    @camera    = recording.camera
    @court     = recording.court
  end

  def start!
    FileUtils.mkdir_p(BASE_PATH)

    output = BASE_PATH.join(filename)

    pid = spawn(
      "ffmpeg -f v4l2 -video_size 1920x1080 -i #{@camera.device_path} -c:v libx264 -movflags +frag_keyframe+empty_moov #{output}"
    )

    Process.detach(pid)

    @recording.update!(
      started_at: Time.current,
      active: true,
      file_path: output.to_s
    )

    Rails.cache.write(pid_key, pid)
  end

  def stop!
    pid = Rails.cache.read(pid_key)
    return unless pid

    Process.kill("INT", pid)

    # ⏳ tunggu sampai benar-benar mati
    begin
      Timeout.timeout(2) do
        loop do
          Process.getpgid(pid)
          sleep 0.05
        end
      end
    rescue Errno::ESRCH, Timeout::Error
      # sudah mati
    end

    Rails.cache.delete(pid_key)

    @recording.update!(
      stopped_at: Time.current,
      active: false
    )
  end

  private

  def filename
    "court#{@court.id}_camera#{@camera.id}_#{Time.now.to_i}.mp4"
  end

  def pid_key
    "recording:#{@recording.id}:pid"
  end
end

