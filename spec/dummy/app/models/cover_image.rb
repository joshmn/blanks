# frozen_string_literal: true

class CoverImage < ApplicationRecord
  belongs_to :article

  validates :url, presence: true
end
