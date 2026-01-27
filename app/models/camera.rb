class Camera < ApplicationRecord
  belongs_to :court
  has_many :recordings, dependent: :destroy

  validates :camera_uid, presence: true, uniqueness: true

  enum :camera_type, {
    usb: "usb",
    rtsp: "rtsp"
  }

  validate :validate_rtsp_stream, if: :rtsp?

  def input_source
    usb? ? device_path : rtsp_url
  end

  private

  def validate_rtsp_stream
    return if rtsp_url.blank?

    unless RtspValidator.valid?(rtsp_url)
      errors.add(:rtsp_url, "RTSP stream tidak dapat diakses")
    end
  end
end

