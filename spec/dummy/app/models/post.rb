# frozen_string_literal: true

class Post < ApplicationRecord
  has_one_attached :featured_image

  validates :title, presence: true, length: { minimum: 3 }
  validates :content, presence: true
end
