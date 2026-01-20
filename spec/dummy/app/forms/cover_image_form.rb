# frozen_string_literal: true

class CoverImageForm < Blanks::Base
  attribute :id, :integer
  attribute :url, :string
  attribute :alt_text, :string

  validates :url, presence: true
end
