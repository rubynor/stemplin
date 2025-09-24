class CreatePets < ActiveRecord::Migration[7.1]
  def change
    create_table :pets do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.integer :hp, default: 100
      t.time :last_fed
      t.integer :food_stock, default: 5
      t.time :died_at, null: true, default: nil

      t.timestamps
    end
    ActiveRecord::Base.transaction do
      User.all.each do |user|
        Pet.create!(
          user: user,
          hp: 100,
          last_fed: Time.now,
          food_stock: 5,
          died_at: nil
        )
      end
    end
  end
end
