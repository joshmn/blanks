# frozen_string_literal: true

require "blanks"

class ImageForm < Blanks::Base
  attribute :url, :string
  attribute :caption, :string

  validates :url, presence: true
end

class CoverPhotoForm < Blanks::Base
  attribute :url, :string

  validates :url, presence: true
end

class PostForm < Blanks::Base
  has_one :cover_photo
  has_many :images

  attribute :title, :string
  attribute :content, :string
  attribute :created_at, :datetime, default: -> { Time.current }

  validates :title, presence: true
  validates :content, presence: true
  validates :created_at, presence: true
end

form = PostForm.new
puts "empty form valid: #{form.valid?}"

form = PostForm.new(
  title: "hello world",
  content: "this is content",
  created_at: Time.now,
  cover_photo_attributes: { url: "https://example.com/cover.jpg" },
  images_attributes: [
    { url: "https://example.com/1.jpg", caption: "first" },
    { url: "https://example.com/2.jpg", caption: "second" }
  ]
)

puts "form with attributes valid: #{form.valid?}"
puts "title: #{form.title}"
puts "cover photo url: #{form.cover_photo.url}"
puts "images count: #{form.images.count}"

form = PostForm.new
form.images.new(url: "https://example.com/new.jpg", caption: "new image")
puts "form with new image count: #{form.images.count}"
