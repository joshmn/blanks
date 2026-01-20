# frozen_string_literal: true

require "blanks"

class ImageForm < Blanks::Base
  attribute :id, :integer
  attribute :url, :string
  attribute :caption, :string

  validates :url, presence: true
end

class PostForm < Blanks::Base
  has_many :images

  attribute :id, :integer
  attribute :title, :string
  attribute :content, :string

  validates :title, presence: true

  before_validation :normalize_title

  def normalize_title
    self.title = title&.strip if title
  end
end

puts "=== dirty tracking ==="
form = PostForm.new(title: "original")
puts "initial: #{form.title}"

form.title = "changed"
puts "changed?: #{form.title_changed?}"
puts "was: #{form.title_was}"
puts "changes: #{form.changes.inspect}"

puts "\n=== callbacks ==="
form = PostForm.new(title: "  HELLO  ")
form.valid?
puts "normalized title: #{form.title}"

puts "\n=== model_attributes (just top-level) ==="
form = PostForm.new(title: "test", content: "content")
form.images.new(url: "image.jpg")
puts form.model_attributes.inspect

puts "\n=== attributes (includes nested) ==="
puts form.attributes.inspect

puts "\n=== id tracking in nested forms ==="
mock_image1 = Struct.new(:id, :url, :caption).new(1, "original1.jpg", "first")
mock_image2 = Struct.new(:id, :url, :caption).new(2, "original2.jpg", "second")
mock_post = Struct.new(:id, :title, :content, :images).new(
  100,
  "my post",
  "my content",
  [mock_image1, mock_image2]
)

form = PostForm.from_model(mock_post)
puts "loaded from model, images count: #{form.images.count}"

form.images_attributes = [
  { id: 1, url: "updated1.jpg" },
  { url: "new.jpg", caption: "new image" }
]

puts "after update, images count: #{form.images.count}"
puts "image 1 url: #{form.images[0].url}"
puts "image 2 url: #{form.images[1].url}"
puts "image 3 url: #{form.images[2].url}"

puts "\n=== using with activerecord ==="
puts "for create:"
puts "Post.create!(form.attributes)"
puts form.attributes.inspect

puts "\nfor update:"
puts "post.update!(form.model_attributes)"
puts form.model_attributes.inspect
