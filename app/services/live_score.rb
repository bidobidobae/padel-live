# app/services/live_score.rb
class LiveScore
  def self.get(court_id)
    Rails.cache.fetch("live_score:#{court_id}") do
      { a: 0, b: 0 }
    end
  end

  def self.increment(court_id, side)
    score = get(court_id)
    score[side] += 1
    Rails.cache.write("live_score:#{court_id}", score)
    score
  end
end

