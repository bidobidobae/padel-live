class AddScoreModeToCourts < ActiveRecord::Migration[8.1]
  def change
    add_column :courts, :score_mode, :string
    add_column :courts, :score_settings, :jsonb
  end
end
