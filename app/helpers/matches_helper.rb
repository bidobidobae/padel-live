module MatchesHelper
  def match_score(match)
    r = match.result || {}

    if match.score_mode == "international"
      "#{r['sets_a']}-#{r['sets_b']} | #{r['games_a']}-#{r['games_b']}"
    else
      "#{r['score_a']} - #{r['score_b']}"
    end
  end
end

