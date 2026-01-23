class Recording < ApplicationRecord
  belongs_to :court
  belongs_to :camera

  scope :finished, -> { where(active: false) }
end
