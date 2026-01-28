# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Seeding players..."

Player.destroy_all

first_names = %w[
  Abah Mang Udin Budi Andi Dedi Rudi Agus Fajar Rizky Bayu
  Iwan Dika Arif Yoga Rian Hendra Tono Wahyu Ilham Rama Aldi
]

last_names = %w[
  Santoso Wijaya Saputra Pratama Nugroho Kurniawan Setiawan Hidayat
  Firmansyah Gunawan Permana Suryadi Ramadhan Putra Maulana Hakim
  Fauzi Akbar Purnomo
]

players = []

100.times do
  first = first_names.sample
  last  = last_names.sample

  name = "#{first} #{last}"

  players << {
    name: name,
    created_at: Time.current,
    updated_at: Time.current
  }
end

Player.insert_all(players)

puts "✅ 100 Players created"

