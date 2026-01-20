# frozen_string_literal: true

class CreateCoverImages < ActiveRecord::Migration[7.0]
  def change
    create_table :cover_images do |t|
      t.references :article, null: false, foreign_key: true
      t.string :url, null: false
      t.string :alt_text
      t.timestamps
    end
  end
end
