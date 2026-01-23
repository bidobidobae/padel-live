class CameraDetector
  UID_REGEX = /\((usb-[^)]+)\)/

  def self.list
    output = `v4l2-ctl --list-devices`
    cameras = []
    current = nil

    output.each_line do |line|
      line = line.strip

      # Header camera
      if line.end_with?(":")
        name = line.delete_suffix(":")
        uid = name[UID_REGEX, 1]

        current = {
          name: name,
          uid: uid,
          devices: []
        }

        cameras << current
        next
      end

      # Device path
      if line.start_with?("/dev/video") && current
        # FILTER: hanya Video Capture (bukan metadata)
        if video_capture_device?(line)
          current[:devices] << line
        end
      end
    end

    cameras.select { |c| c[:uid].present? && c[:devices].any? }
  end

  def self.video_capture_device?(device)
    info = `v4l2-ctl -d #{device} --all 2>/dev/null`

    device_caps_section = info.split("Device Caps").last
    return false unless device_caps_section

    device_caps_section.include?("Video Capture")
  end

end

