# frozen_string_literal: true

require "spec_helper"

RSpec.describe Blanks::NestedAttributes do
  describe "nested attributes for has_one" do
    it "assigns attributes to existing association" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :photo
      end

      form = form_class.new
      form.build_photo
      form.photo_attributes = { url: "https://example.com" }

      expect(form.photo.url).to eq("https://example.com")
    end

    it "creates association if not present" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :photo
      end

      form = form_class.new
      form.photo_attributes = { url: "https://example.com" }

      expect(form.photo.url).to eq("https://example.com")
    end

    it "works through initialization" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :photo
        attribute :title, :string
      end

      form = form_class.new(
        title: "test",
        photo_attributes: { url: "https://example.com" }
      )

      expect(form.photo.url).to eq("https://example.com")
    end

    it "handles blank attributes" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :photo
      end

      form = form_class.new
      form.photo_attributes = nil

      expect(form.photo).to be_nil
    end
  end

  describe "nested attributes for has_many" do
    it "creates multiple associated forms from array" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("ImageForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images
      end

      form = form_class.new
      form.images_attributes = [
        { url: "https://example.com/1.jpg" },
        { url: "https://example.com/2.jpg" }
      ]

      expect(form.images.count).to eq(2)
    end

    it "creates multiple associated forms from hash" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("ImageForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images
      end

      form = form_class.new
      form.images_attributes = {
        "0" => { url: "https://example.com/1.jpg" },
        "1" => { url: "https://example.com/2.jpg" }
      }

      expect(form.images.count).to eq(2)
    end

    it "works through initialization" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("ImageForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images
        attribute :title, :string
      end

      form = form_class.new(
        title: "test",
        images_attributes: [
          { url: "https://example.com/1.jpg" },
          { url: "https://example.com/2.jpg" }
        ]
      )

      expect(form.images.count).to eq(2)
    end

    it "handles blank attributes" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("ImageForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images
      end

      form = form_class.new
      form.images_attributes = nil

      expect(form.images.count).to eq(0)
    end

    it "supports reject_if option" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("ImageForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images, reject_if: ->(attrs) { attrs[:url].blank? }
      end

      form = form_class.new
      form.images_attributes = [
        { url: "https://example.com/1.jpg" },
        { url: "" },
        { url: "https://example.com/2.jpg" }
      ]

      expect(form.images.count).to eq(2)
    end

    it "supports reject_if with symbol" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("ImageForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images, reject_if: :reject_blank_url

        def reject_blank_url(attrs)
          attrs[:url].blank?
        end
      end

      form = form_class.new
      form.images_attributes = [
        { url: "https://example.com/1.jpg" },
        { url: "" }
      ]

      expect(form.images.count).to eq(1)
    end
  end

  describe "allow_destroy for has_one" do
    it "marks association for destruction when allow_destroy is true" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :photo, allow_destroy: true
      end

      form = form_class.new
      form.build_photo(url: "https://example.com")
      form.photo_attributes = { _destroy: true }

      expect(form.photo.marked_for_destruction?).to be true
    end

    it "does not mark for destruction when allow_destroy is false" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :photo
      end

      form = form_class.new
      form.build_photo(url: "https://example.com")
      form.photo_attributes = { _destroy: true }

      expect(form.photo.marked_for_destruction?).to be false
    end

    it "handles string values for _destroy" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :photo, allow_destroy: true
      end

      form = form_class.new
      form.build_photo(url: "https://example.com")
      form.photo_attributes = { _destroy: "1" }

      expect(form.photo.marked_for_destruction?).to be true
    end

    it "includes _destroy in attributes when marked for destruction" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("PhotoForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_one :photo, allow_destroy: true
      end

      form = form_class.new
      form.build_photo(url: "https://example.com")
      form.photo.mark_for_destruction

      expect(form.attributes["photo_attributes"]["_destroy"]).to be true
    end
  end

  describe "allow_destroy for has_many" do
    it "marks existing record for destruction when allow_destroy is true" do
      nested_class = Class.new(Blanks::Base) do
        attribute :id, :integer
        attribute :url, :string
      end
      stub_const("ImageForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images, allow_destroy: true
      end

      form = form_class.new
      form.images.new(id: 1, url: "https://example.com/1.jpg")
      form.images.new(id: 2, url: "https://example.com/2.jpg")

      form.images_attributes = [
        { id: 1, _destroy: true },
        { id: 2, url: "updated.jpg" }
      ]

      expect(form.images[0].marked_for_destruction?).to be true
      expect(form.images[1].marked_for_destruction?).to be false
    end

    it "does not mark for destruction when allow_destroy is false" do
      nested_class = Class.new(Blanks::Base) do
        attribute :id, :integer
        attribute :url, :string
      end
      stub_const("ImageForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images
      end

      form = form_class.new
      form.images.new(id: 1, url: "https://example.com/1.jpg")
      form.images_attributes = [{ id: 1, _destroy: true }]

      expect(form.images[0].marked_for_destruction?).to be false
    end

    it "ignores _destroy for new records without id" do
      nested_class = Class.new(Blanks::Base) do
        attribute :url, :string
      end
      stub_const("ImageForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images, allow_destroy: true
      end

      form = form_class.new
      form.images_attributes = [
        { url: "https://example.com/1.jpg", _destroy: true }
      ]

      expect(form.images.count).to eq(0)
    end

    it "includes _destroy in attributes for marked records" do
      nested_class = Class.new(Blanks::Base) do
        attribute :id, :integer
        attribute :url, :string
      end
      stub_const("ImageForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images, allow_destroy: true
      end

      form = form_class.new
      form.images.new(id: 1, url: "https://example.com/1.jpg")
      form.images[0].mark_for_destruction

      attrs = form.attributes["images_attributes"]
      expect(attrs[0]["_destroy"]).to be true
    end

    it "handles mixed destroy and update operations" do
      nested_class = Class.new(Blanks::Base) do
        attribute :id, :integer
        attribute :url, :string
      end
      stub_const("ImageForm", nested_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images, allow_destroy: true
      end

      form = form_class.new
      form.images.new(id: 1, url: "keep.jpg")
      form.images.new(id: 2, url: "delete.jpg")
      form.images.new(id: 3, url: "update.jpg")

      form.images_attributes = [
        { id: 1, url: "keep.jpg" },
        { id: 2, _destroy: "1" },
        { id: 3, url: "updated.jpg" },
        { url: "new.jpg" }
      ]

      expect(form.images.count).to eq(4)
      expect(form.images[0].marked_for_destruction?).to be false
      expect(form.images[1].marked_for_destruction?).to be true
      expect(form.images[2].url).to eq("updated.jpg")
      expect(form.images[3].url).to eq("new.jpg")
    end
  end

end
