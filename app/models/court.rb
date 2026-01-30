class Court < ApplicationRecord
  has_many :cameras, dependent: :destroy
  has_many :recordings, dependent: :destroy
  has_many :court_players, dependent: :destroy
  has_many :players, through: :court_players
  has_many :matches, dependent: :destroy

  after_commit :broadcast_live_score, on: [:update]
  after_initialize :set_default_score_config

  def side_players(side)
    court_players
      .includes(:player)
      .where(side: side)
      .order(:position)
      .map(&:player)
  end

  def side_label(side)
    list = side_players(side)
    return "SIDE #{side.to_s.capitalize}" if list.empty?
    list.map do |player|
      format_player_name(player.name)
    end.join(" / ")
  end

  def side_label_br(side)
    list = side_players(side)
    return "SIDE #{side.to_s.capitalize}" if list.empty?
    list.map do |player|
      format_player_name(player.name)
    end.join("</br>").html_safe
  end

  def format_player_name(name)
    parts = name.strip.split(" ")

    return name if parts.length == 1

    first_initial = parts.first[0].capitalize
    last_name = parts.last.capitalize

    "#{first_initial} #{last_name}".capitalize
  end


  def broadcast_live_score
    score = Rails.cache.read("court:#{id}:score")
    return unless score

    Turbo::StreamsChannel.broadcast_replace_to(
      "court_#{id}",
      target: "score",
      partial: "lives/score",
      locals: {
        score: score,
        court: self
      }
    )
  end


  private

  def set_default_score_config
    self.score_mode ||= "americano"

    self.score_settings ||= case score_mode
    when "americano"
      { target: 21 }
    when "international"
      {
        sets_to_win: 2,
        games_per_set: 6,
        deuce: true,
        advantage: true
      }
    else
      {}
    end
  end
end

