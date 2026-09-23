class CreateExchangeRates < ActiveRecord::Migration[7.1]
  def change
    create_table :exchange_rates do |t|
      t.string :currency, null: false
      t.decimal :rate_to_usd, precision: 12, scale: 6, null: false

      t.timestamps
    end
    add_index :exchange_rates, :currency, unique: true
  end
end
