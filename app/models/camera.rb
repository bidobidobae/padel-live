class Camera < ApplicationRecord
  belongs_to :court
  has_many :recordings
  validates :camera_uid, presence: true, uniqueness: true
end
