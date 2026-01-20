# frozen_string_literal: true

class TagForm < Blanks::Base
  attribute :id, :integer
  attribute :name, :string
  attribute :color, :string

  normalizes :color, with: ->(color) { color&.downcase }
  normalizes :name, with: ->(name) { name&.strip }

  validates :name, presence: true
end
