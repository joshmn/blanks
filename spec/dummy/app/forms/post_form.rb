# frozen_string_literal: true

class PostForm < Blanks::Base
  inherit_attributes_from Post, only: [:id, :title, :content, :published]
  inherit_validations_from Post, only: [:title]

  normalizes :title, with: ->(title) { title.strip }

  validates :content, presence: true
end
