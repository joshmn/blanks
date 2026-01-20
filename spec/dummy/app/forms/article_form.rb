# frozen_string_literal: true

class ArticleForm < Blanks::Base
  attribute :id, :integer
  attribute :title, :string
  attribute :body, :string
  attribute :author_name, :string

  has_one :cover_image
  has_many :tags, allow_destroy: true

  normalizes :title, with: ->(title) { title&.strip }
  normalizes :author_name, with: ->(name) { name&.strip }

  validates :title, presence: true
  validates :body, presence: true
end
