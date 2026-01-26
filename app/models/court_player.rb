class CourtPlayer < ApplicationRecord
  belongs_to :court
  belongs_to :player

  validates :side, inclusion: { in: %w[a b] }
  validates :position, inclusion: { in: [1, 2] }

  after_commit :broadcast_live

  def broadcast_live
    court.broadcast_live_score
  end

end

