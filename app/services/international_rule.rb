class InternationalRule

  POINTS = [0, 15, 30, 40]

  def self.apply(score, settings, side, delta)
    return score if delta < 0
    return score if score[:winner].present?

    games_target = (settings["games_per_set"] || 6).to_i
    sets_target  = (settings["sets_to_win"] || 2).to_i
    deuce_on     = settings["deuce"] != false
    adv_on       = settings["advantage"] != false

    other = side == :a ? :b : :a

    # ===== NORMAL POINT =====
    if score[side] < 40
      score[side] = POINTS[POINTS.index(score[side]) + 1]
      return score
    end

    # ===== DEUCE =====
    if deuce_on && score[:a] == 40 && score[:b] == 40

      if adv_on
        if score[:advantage].nil?
          score[:advantage] = side
          return score
        end

        if score[:advantage] == side
          win_game(score, side, games_target, sets_target)
        else
          score[:advantage] = nil
        end

        return score
      else
        win_game(score, side, games_target, sets_target)
        return score
      end
    end

    # ===== NORMAL GAME WIN =====
    if score[side] == 40 && score[other] < 40
      win_game(score, side, games_target, sets_target)
    end

    score
  end

  private

  def self.win_game(score, side, games_target, sets_target)

    score[:"games_#{side}"] ||= 0
    score[:"games_#{side}"] += 1

    # ===== CEK SET =====
    set_finished = check_set(score, side, games_target, sets_target)

    # ⚠ RESET POINT HANYA JIKA MATCH BELUM SELESAI
    unless score[:winner].present?
      score[:a] = 0
      score[:b] = 0
      score[:advantage] = nil
    end

    score
  end

  def self.check_set(score, side, games_target, sets_target)

    other = side == :a ? :b : :a
    lead = score[:"games_#{side}"] - score[:"games_#{other}"]

    return false unless score[:"games_#{side}"] >= games_target && lead >= 2

    score[:"sets_#{side}"] ||= 0
    score[:"sets_#{side}"] += 1

    # ===== CEK MATCH =====
    match_finished = check_match(score, side, sets_target)

    # ⚠ RESET GAME HANYA JIKA MATCH BELUM SELESAI
    unless match_finished
      score[:games_a] = 0
      score[:games_b] = 0
    end

    true
  end

  def self.check_match(score, side, sets_target)

    if score[:"sets_#{side}"] >= sets_target
      score[:winner] = side
      return true
    end

    false
  end

end

