# frozen_string_literal: true

class Article < ApplicationRecord
  has_one :cover_image, dependent: :destroy
  has_many :tags, dependent: :destroy

  accepts_nested_attributes_for :cover_image, allow_destroy: true
  accepts_nested_attributes_for :tags, allow_destroy: true

  validates :title, presence: true
end
