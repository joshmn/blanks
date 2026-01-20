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
  attribute :created_at, :datetime

  validates :title, presence: true
  validates :content, presence: true
  validates :created_at, presence: true
end

MockImage = Struct.new(:url, :caption, keyword_init: true)
MockCoverPhoto = Struct.new(:url, keyword_init: true)
MockPost = Struct.new(:title, :content, :created_at, :cover_photo, :images, keyword_init: true)

mock_post = MockPost.new(
  title: "model title",
  content: "model content",
  created_at: Time.now,
  cover_photo: MockCoverPhoto.new(url: "https://example.com/model-cover.jpg"),
  images: [
    MockImage.new(url: "https://example.com/model-1.jpg", caption: "model image 1"),
    MockImage.new(url: "https://example.com/model-2.jpg", caption: "model image 2")
  ]
)

form = PostForm.from_model(mock_post)

puts "form valid: #{form.valid?}"
puts "title: #{form.title}"
puts "content: #{form.content}"
puts "cover photo url: #{form.cover_photo.url}"
puts "images count: #{form.images.count}"
puts "first image url: #{form.images[0].url}"
puts "first image caption: #{form.images[0].caption}"
