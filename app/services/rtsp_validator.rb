class RtspValidator
  TIMEOUT = 5

  def self.valid?(url)
    cmd = [
      "ffprobe",
      "-v error",
      "-rtsp_transport tcp",
      "-select_streams v:0",
      "-show_entries stream=codec_type",
      "-of csv=p=0",
      url
    ]

    output = ""

    begin
      Timeout.timeout(TIMEOUT) do
        output = `#{cmd.join(" ")}`
      end
    rescue Timeout::Error
      Rails.logger.warn "RTSP validation timeout"
      return false
    end

    output.include?("video")
  rescue => e
    Rails.logger.error "RTSP validation error: #{e.message}"
    false
  end
end

