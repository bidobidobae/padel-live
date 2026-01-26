class Player < ApplicationRecord
  has_many :court_players, dependent: :destroy
  has_many :courts, through: :court_players

  validates :name, presence: true
end

