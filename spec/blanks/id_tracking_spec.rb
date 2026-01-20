# frozen_string_literal: true

require "spec_helper"

RSpec.describe "ID tracking in nested forms" do
  describe "AssociationProxy#find_by_id" do
    it "finds form by id" do
      form_class = Class.new(Blanks::Base) do
        attribute :id, :integer
        attribute :url, :string
      end
      stub_const("ImageForm", form_class)

      proxy = Blanks::AssociationProxy.new("ImageForm")
      image = proxy.new(id: 123, url: "test.jpg")

      expect(proxy.find_by_id(123)).to eq(image)
    end

    it "returns nil when id not found" do
      form_class = Class.new(Blanks::Base) do
        attribute :id, :integer
        attribute :url, :string
      end
      stub_const("ImageForm", form_class)

      proxy = Blanks::AssociationProxy.new("ImageForm")

      expect(proxy.find_by_id(999)).to be_nil
    end

    it "handles string and integer ids" do
      form_class = Class.new(Blanks::Base) do
        attribute :id, :integer
        attribute :url, :string
      end
      stub_const("ImageForm", form_class)

      proxy = Blanks::AssociationProxy.new("ImageForm")
      image = proxy.new(id: 123, url: "test.jpg")

      expect(proxy.find_by_id("123")).to eq(image)
    end
  end

  describe "updating existing nested forms by id" do
    it "updates existing form when id matches" do
      image_form_class = Class.new(Blanks::Base) do
        attribute :id, :integer
        attribute :url, :string
      end
      stub_const("ImageForm", image_form_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images
        attribute :title, :string
      end

      form = form_class.new(title: "test")
      form.images.new(id: 1, url: "original.jpg")
      form.images.new(id: 2, url: "another.jpg")

      form.images_attributes = [
        { id: 1, url: "updated.jpg" }
      ]

      expect(form.images[0].url).to eq("updated.jpg")
    end

    it "creates new form when id not found" do
      image_form_class = Class.new(Blanks::Base) do
        attribute :id, :integer
        attribute :url, :string
      end
      stub_const("ImageForm", image_form_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images
        attribute :title, :string
      end

      form = form_class.new(title: "test")
      form.images.new(id: 1, url: "original.jpg")

      form.images_attributes = [
        { id: 999, url: "new.jpg" }
      ]

      expect(form.images.count).to eq(2)
    end

    it "creates new form when no id provided" do
      image_form_class = Class.new(Blanks::Base) do
        attribute :id, :integer
        attribute :url, :string
      end
      stub_const("ImageForm", image_form_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images
        attribute :title, :string
      end

      form = form_class.new(title: "test")
      form.images.new(id: 1, url: "original.jpg")

      form.images_attributes = [
        { url: "new.jpg" }
      ]

      expect(form.images.count).to eq(2)
    end

    it "preserves unchanged forms" do
      image_form_class = Class.new(Blanks::Base) do
        attribute :id, :integer
        attribute :url, :string
      end
      stub_const("ImageForm", image_form_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images
        attribute :title, :string
      end

      form = form_class.new(title: "test")
      form.images.new(id: 1, url: "first.jpg")
      form.images.new(id: 2, url: "second.jpg")

      form.images_attributes = [
        { id: 1, url: "updated.jpg" }
      ]

      expect(form.images.count).to eq(2)
      expect(form.images[0].url).to eq("updated.jpg")
      expect(form.images[1].url).to eq("second.jpg")
    end

    it "works with from_model then update" do
      model_image1 = Struct.new(:id, :url).new(1, "model1.jpg")
      model_image2 = Struct.new(:id, :url).new(2, "model2.jpg")
      model = Struct.new(:title, :images).new("test", [model_image1, model_image2])

      image_form_class = Class.new(Blanks::Base) do
        attribute :id, :integer
        attribute :url, :string
      end
      stub_const("ImageForm", image_form_class)

      form_class = Class.new(Blanks::Base) do
        has_many :images
        attribute :title, :string
      end

      form = form_class.from_model(model)

      form.images_attributes = [
        { id: 1, url: "updated1.jpg" },
        { url: "new.jpg" }
      ]

      expect(form.images.count).to eq(3)
      expect(form.images[0].url).to eq("updated1.jpg")
      expect(form.images[1].url).to eq("model2.jpg")
      expect(form.images[2].url).to eq("new.jpg")
    end
  end
end
