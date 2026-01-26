class ScoreState

  def self.default_for(court)
    base = {
      a: 0,
      b: 0,
      winner: nil,
      started: false
    }

    case court.score_mode
    when "americano"
      base

    when "international"
      base.merge(
        games_a: 0,
        games_b: 0,
        sets_a: 0,
        sets_b: 0,
        advantage: nil
      )

    else
      base
    end
  end

end

