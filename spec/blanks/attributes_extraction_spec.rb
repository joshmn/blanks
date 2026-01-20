# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Attributes extraction" do
  describe "#model_attributes" do
    it "returns hash of form attributes" do
      form_class = Class.new(Blanks::Base) do
        attribute :title, :string
        attribute :content, :string
      end

      form = form_class.new(title: "hello", content: "world")

      expect(form.model_attributes).to eq("title" => "hello", "content" => "world")
    end

    it "excludes associations" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :photo
        attribute :title, :string
      end

      form = form_class.new(title: "test")
      form.build_photo(url: "https://example.com")

      expect(form.model_attributes.keys).to eq(["title"])
    end

    it "includes nil values" do
      form_class = Class.new(Blanks::Base) do
        attribute :title, :string
        attribute :count, :integer
      end

      form = form_class.new(title: "test")

      expect(form.model_attributes).to eq("title" => "test", "count" => nil)
    end
  end

  describe "#attributes" do
    it "returns hash with nested attributes" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :photo
        attribute :title, :string
      end

      form = form_class.new(title: "test")
      form.build_photo(url: "https://example.com")

      expect(form.attributes).to eq(
        "title" => "test",
        "photo_attributes" => { "url" => "https://example.com" }
      )
    end

    it "includes has_many associations as array" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("ImageForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images
        attribute :title, :string
      end

      form = form_class.new(title: "test")
      form.images.new(url: "https://example.com/1.jpg")
      form.images.new(url: "https://example.com/2.jpg")

      expect(form.attributes).to eq(
        "title" => "test",
        "images_attributes" => [
          { "url" => "https://example.com/1.jpg" },
          { "url" => "https://example.com/2.jpg" }
        ]
      )
    end

    it "recursively converts nested associations" do
      deepest_class = Class.new(Blanks::Base) do
        attribute :caption, :string
      end
      stub_const("CaptionForm", deepest_class)

      nested_class = Class.new(Blanks::Base) do
        has_one :caption
        attribute :url, :string
      end
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :photo
        attribute :title, :string
      end

      form = form_class.new(title: "test")
      form.build_photo(url: "https://example.com")
      form.photo.build_caption(caption: "test caption")

      expect(form.attributes).to eq(
        "title" => "test",
        "photo_attributes" => {
          "url" => "https://example.com",
          "caption_attributes" => { "caption" => "test caption" }
        }
      )
    end

    it "omits nil associations" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :photo
        attribute :title, :string
      end

      form = form_class.new(title: "test")

      expect(form.attributes).to eq("title" => "test")
    end
  end
end
