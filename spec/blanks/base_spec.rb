# frozen_string_literal: true

require "spec_helper"

RSpec.describe Blanks::Base do
  describe ".attribute" do
    it "defines an attribute with a type" do
      form_class = Class.new(described_class) do
        attribute :title, :string
      end

      form = form_class.new(title: "hello")

      expect(form.title).to eq("hello")
    end

    it "supports default values" do
      form_class = Class.new(described_class) do
        attribute :status, :string, default: "draft"
      end

      form = form_class.new

      expect(form.status).to eq("draft")
    end

    it "supports default values from proc" do
      form_class = Class.new(described_class) do
        attribute :timestamp, :datetime, default: -> { Time.new(2025, 1, 1) }
      end

      form = form_class.new

      expect(form.timestamp).to eq(Time.new(2025, 1, 1))
    end
  end

  describe "#initialize" do
    it "accepts a hash of attributes" do
      form_class = Class.new(described_class) do
        attribute :title, :string
        attribute :count, :integer
      end

      form = form_class.new(title: "test", count: 5)

      expect(form.title).to eq("test")
    end

    it "accepts an empty hash" do
      form_class = Class.new(described_class)

      form = form_class.new({})

      expect(form).to be_a(described_class)
    end
  end

  describe "#assign_attributes" do
    it "assigns multiple attributes" do
      form_class = Class.new(described_class) do
        attribute :title, :string
        attribute :content, :string
      end

      form = form_class.new
      form.assign_attributes(title: "new title", content: "new content")

      expect(form.title).to eq("new title")
    end

    it "handles nested attributes with _attributes suffix" do
      nested_class = Class.new(described_class) do
        attribute :url, :string
      end
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(described_class) do
        has_one :photo
        attribute :title, :string
      end

      form = form_class.new
      form.assign_attributes(photo_attributes: { url: "https://example.com" })

      expect(form.photo.url).to eq("https://example.com")
    end
  end

  describe ".from_model" do
    it "creates new instance from model" do
      model = Struct.new(:title, :content).new("model title", "model content")

      form_class = Class.new(described_class) do
        attribute :title, :string
        attribute :content, :string
      end

      form = form_class.from_model(model)

      expect(form.title).to eq("model title")
    end
  end

  describe "#from_model" do
    it "copies matching attributes from model" do
      model = Struct.new(:title, :content).new("model title", "model content")

      form_class = Class.new(described_class) do
        attribute :title, :string
        attribute :content, :string
      end

      form = form_class.new
      form.from_model(model)

      expect(form.title).to eq("model title")
    end

    it "returns self for chaining" do
      model = Struct.new(:title).new("title")

      form_class = Class.new(described_class) do
        attribute :title, :string
      end

      form = form_class.new
      result = form.from_model(model)

      expect(result).to eq(form)
    end

    it "ignores attributes not defined on form" do
      model = Struct.new(:title, :extra).new("title", "extra")

      form_class = Class.new(described_class) do
        attribute :title, :string
      end

      form = form_class.new
      form.from_model(model)

      expect(form.title).to eq("title")
    end

    it "handles nil model" do
      form_class = Class.new(described_class) do
        attribute :title, :string
      end

      form = form_class.new
      form.from_model(nil)

      expect(form.title).to be_nil
    end

    it "assigns has_one associations from model" do
      model_photo = Struct.new(:url).new("https://example.com/photo.jpg")
      model = Struct.new(:title, :photo).new("test", model_photo)

      photo_form_class = Class.new(described_class) do
        attribute :url, :string
      end
      stub_const("PhotoForm", photo_form_class)

      form_class = Class.new(described_class) do
        has_one :photo
        attribute :title, :string
      end

      form = form_class.new
      form.from_model(model)

      expect(form.photo.url).to eq("https://example.com/photo.jpg")
    end

    it "assigns has_many associations from model" do
      model_image1 = Struct.new(:url).new("https://example.com/1.jpg")
      model_image2 = Struct.new(:url).new("https://example.com/2.jpg")
      model = Struct.new(:title, :images).new("test", [model_image1, model_image2])

      image_form_class = Class.new(described_class) do
        attribute :url, :string
      end
      stub_const("ImageForm", image_form_class)

      form_class = Class.new(described_class) do
        has_many :images
        attribute :title, :string
      end

      form = form_class.new
      form.from_model(model)

      expect(form.images.count).to eq(2)
    end
  end

  describe "#persisted?" do
    it "returns false when id is not present" do
      form_class = Class.new(described_class) do
        attribute :id, :integer
      end

      form = form_class.new

      expect(form.persisted?).to be(false)
    end

    it "returns true when id is present" do
      form_class = Class.new(described_class) do
        attribute :id, :integer
      end

      form = form_class.new(id: 123)

      expect(form.persisted?).to be(true)
    end

    it "returns false when id attribute is not defined" do
      form_class = Class.new(described_class)

      form = form_class.new

      expect(form.persisted?).to be(false)
    end
  end

  describe "#to_key" do
    it "returns nil when not persisted" do
      form_class = Class.new(described_class) do
        attribute :id, :integer
      end

      form = form_class.new

      expect(form.to_key).to be_nil
    end

    it "returns array with id when persisted" do
      form_class = Class.new(described_class) do
        attribute :id, :integer
      end

      form = form_class.new(id: 456)

      expect(form.to_key).to eq([456])
    end
  end

  describe "#to_param" do
    it "returns nil when not persisted" do
      form_class = Class.new(described_class) do
        attribute :id, :integer
      end

      form = form_class.new

      expect(form.to_param).to be_nil
    end

    it "returns id as string when persisted" do
      form_class = Class.new(described_class) do
        attribute :id, :integer
      end

      form = form_class.new(id: 789)

      expect(form.to_param).to eq("789")
    end
  end

  describe "#to_model" do
    it "returns self" do
      form_class = Class.new(described_class)

      form = form_class.new

      expect(form.to_model).to eq(form)
    end
  end

  describe "#valid?" do
    it "returns true when all validations pass" do
      form_class = Class.new(described_class) do
        attribute :title, :string
        validates :title, presence: true
      end

      form = form_class.new(title: "present")

      expect(form.valid?).to be(true)
    end

    it "returns false when validations fail" do
      form_class = Class.new(described_class) do
        attribute :title, :string
        validates :title, presence: true
      end

      form = form_class.new

      expect(form.valid?).to be(false)
    end

    it "validates nested has_one forms" do
      nested_class = Class.new(described_class) do
        attribute :url, :string
        validates :url, presence: true
      end
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(described_class) do
        has_one :photo
        attribute :title, :string
      end

      form = form_class.new(title: "test")
      form.build_photo

      expect(form.valid?).to be(false)
    end

    it "validates nested has_many forms" do
      nested_class = Class.new(described_class) do
        attribute :url, :string
        validates :url, presence: true
      end
      stub_const("ImageForm", nested_class)

      form_class = Class.new(described_class) do
        has_many :images
        attribute :title, :string
      end

      form = form_class.new(title: "test")
      form.images.new

      expect(form.valid?).to be(false)
    end

    it "includes nested form errors in parent errors" do
      nested_class = Class.new(described_class) do
        attribute :url, :string
        validates :url, presence: true
      end
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(described_class) do
        has_one :photo
        attribute :title, :string
      end

      form = form_class.new(title: "test")
      form.build_photo
      form.valid?

      expect(form.errors.messages.keys).to include(:"photo.url")
    end
  end
end
