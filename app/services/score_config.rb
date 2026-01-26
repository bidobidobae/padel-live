class ScoreConfig
  def self.default(mode)
    case mode
    when "americano"
      { "target" => 21 }

    when "international"
      {
        "sets_to_win"   => 2,
        "games_per_set" => 6,
        "deuce"         => true,
        "advantage"     => true
      }

    else
      {}
    end
  end
end

