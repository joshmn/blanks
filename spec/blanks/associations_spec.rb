# frozen_string_literal: true

require "spec_helper"

RSpec.describe Blanks::Associations do
  describe ".has_one" do
    it "defines a reader method" do
      nested_class = Class.new(Blanks::Base)
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :photo
      end

      form = form_class.new

      expect(form).to respond_to(:photo)
    end

    it "defines a setter method" do
      nested_class = Class.new(Blanks::Base)
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :photo
      end

      form = form_class.new

      expect(form).to respond_to(:photo=)
    end

    it "defines a build method" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :photo
      end

      form = form_class.new

      expect(form).to respond_to(:build_photo)
    end

    it "infers class name from association name" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("CoverPhotoForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :cover_photo
      end

      form = form_class.new
      photo = form.build_cover_photo(url: "test")

      expect(photo).to be_a(CoverPhotoForm)
    end

    it "accepts explicit class_name option" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("CustomForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :photo, class_name: "CustomForm"
      end

      form = form_class.new
      photo = form.build_photo(url: "test")

      expect(photo).to be_a(CustomForm)
    end

    it "builds associated form with attributes" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :photo
      end

      form = form_class.new
      photo = form.build_photo(url: "https://example.com")

      expect(photo.url).to eq("https://example.com")
    end

    it "sets the built form on the association" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :photo
      end

      form = form_class.new
      form.build_photo(url: "https://example.com")

      expect(form.photo.url).to eq("https://example.com")
    end
  end

  describe ".has_many" do
    it "defines a reader method" do
      nested_class = Class.new(Blanks::Base)
      stub_const("ImageForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images
      end

      form = form_class.new

      expect(form).to respond_to(:images)
    end

    it "defines a setter method" do
      nested_class = Class.new(Blanks::Base)
      stub_const("ImageForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images
      end

      form = form_class.new

      expect(form).to respond_to(:images=)
    end

    it "returns an association proxy" do
      nested_class = Class.new(Blanks::Base)
      stub_const("ImageForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images
      end

      form = form_class.new

      expect(form.images).to be_a(Blanks::AssociationProxy)
    end

    it "infers class name from singular association name" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("ImageForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images
      end

      form = form_class.new
      image = form.images.new(url: "test")

      expect(image).to be_a(ImageForm)
    end

    it "accepts explicit class_name option" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("CustomForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_many :items, class_name: "CustomForm"
      end

      form = form_class.new
      item = form.items.new(url: "test")

      expect(item).to be_a(CustomForm)
    end
  end
end
