class AmericanoRule

  def self.apply(score, settings, side, delta)
    score[side] = [score[side] + delta, 0].max

    target = (settings["target"] || 21).to_i
    total  = score[:a] + score[:b]

    if total >= target
      score[:winner] = score[:a] > score[:b] ? :a : :b
    else
      score[:winner] = nil
    end

    score
  end

end

