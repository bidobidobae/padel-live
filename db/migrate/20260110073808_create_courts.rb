class CreateCourts < ActiveRecord::Migration[8.1]
  def change
    create_table :courts do |t|
      t.integer :number

      t.timestamps
    end
  end
end
