# frozen_string_literal: true

class CreateTags < ActiveRecord::Migration[7.0]
  def change
    create_table :tags do |t|
      t.references :article, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color
      t.timestamps
    end
  end
end
