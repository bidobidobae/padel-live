class ScoreEngine

  def self.apply(score:, court:, side:, delta:)

    settings =
      ScoreConfig
        .default(court.score_mode)
        .merge(court.score_settings || {})

    case court.score_mode
    when "americano"
      AmericanoRule.apply(score, settings, side, delta)

    when "international"
      InternationalRule.apply(score, settings, side, delta)

    else
      score
    end
  end

end

