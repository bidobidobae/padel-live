class Court < ApplicationRecord
  has_many :cameras, dependent: :destroy
  has_many :recordings, dependent: :destroy
end
