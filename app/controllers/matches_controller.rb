class MatchesController < ApplicationController
  def index
    @matches = Match
      .includes(:court)
      .order(finished_at: :desc)
      .limit(100)
  end
end

