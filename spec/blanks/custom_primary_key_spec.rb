# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Custom primary key for nested forms" do
  before(:all) do
    class CustomPrimaryKeyImageForm < Blanks::Base
      attribute :uuid, :string
      attribute :url, :string
    end

    class CustomPrimaryKeyPostForm < Blanks::Base
      attribute :title, :string
      has_many :images, class_name: "CustomPrimaryKeyImageForm", primary_key: :uuid
    end
  end

  after(:all) do
    Object.send(:remove_const, :CustomPrimaryKeyImageForm)
    Object.send(:remove_const, :CustomPrimaryKeyPostForm)
  end

  describe "has_many with custom primary_key" do
    it "uses custom primary_key to find existing records" do
      form = CustomPrimaryKeyPostForm.new
      form.images.new(uuid: "abc-123", url: "original.jpg")

      form.images_attributes = [
        { uuid: "abc-123", url: "updated.jpg" }
      ]

      expect(form.images.count).to eq(1)
      expect(form.images.first.url).to eq("updated.jpg")
      expect(form.images.first.uuid).to eq("abc-123")
    end

    it "creates new record when primary_key value not found" do
      form = CustomPrimaryKeyPostForm.new
      form.images.new(uuid: "abc-123", url: "original.jpg")

      form.images_attributes = [
        { uuid: "def-456", url: "new.jpg" }
      ]

      expect(form.images.count).to eq(2)
      expect(form.images.map(&:uuid)).to contain_exactly("abc-123", "def-456")
    end

    it "excludes primary_key from updated attributes" do
      form = CustomPrimaryKeyPostForm.new
      form.images.new(uuid: "abc-123", url: "original.jpg")

      form.images_attributes = [
        { uuid: "abc-123", url: "updated.jpg" }
      ]

      image = form.images.first
      expect(image.uuid).to eq("abc-123")
      expect(image.url).to eq("updated.jpg")
    end
  end

  describe "has_many with custom primary_key and allow_destroy" do
    before(:all) do
      class DestroyableImageForm < Blanks::Base
        attribute :uuid, :string
        attribute :url, :string
      end

      class DestroyablePostForm < Blanks::Base
        attribute :title, :string
        has_many :images, class_name: "DestroyableImageForm", primary_key: :uuid, allow_destroy: true
      end
    end

    after(:all) do
      Object.send(:remove_const, :DestroyableImageForm)
      Object.send(:remove_const, :DestroyablePostForm)
    end

    it "marks record for destruction using custom primary_key" do
      form = DestroyablePostForm.new
      form.images.new(uuid: "abc-123", url: "original.jpg")

      form.images_attributes = [
        { uuid: "abc-123", _destroy: true }
      ]

      expect(form.images.first.marked_for_destruction?).to be true
    end
  end

  describe "has_many defaults to :id when no primary_key specified" do
    before(:all) do
      class DefaultIdImageForm < Blanks::Base
        attribute :id, :integer
        attribute :url, :string
      end

      class DefaultIdPostForm < Blanks::Base
        attribute :title, :string
        has_many :images, class_name: "DefaultIdImageForm"
      end
    end

    after(:all) do
      Object.send(:remove_const, :DefaultIdImageForm)
      Object.send(:remove_const, :DefaultIdPostForm)
    end

    it "uses id as default primary_key" do
      form = DefaultIdPostForm.new
      form.images.new(id: 1, url: "original.jpg")

      form.images_attributes = [
        { id: 1, url: "updated.jpg" }
      ]

      expect(form.images.count).to eq(1)
      expect(form.images.first.url).to eq("updated.jpg")
      expect(form.images.first.id).to eq(1)
    end
  end

  describe "AssociationProxy#find_by" do
    before(:all) do
      class ProxyTestForm < Blanks::Base
        attribute :id, :integer
        attribute :uuid, :string
        attribute :url, :string
      end
    end

    after(:all) do
      Object.send(:remove_const, :ProxyTestForm)
    end

    it "finds record by custom attribute" do
      proxy = Blanks::AssociationProxy.new("ProxyTestForm")
      image = ProxyTestForm.new(uuid: "abc-123", url: "test.jpg")
      proxy.push(image)

      found = proxy.find_by(:uuid, "abc-123")

      expect(found).to eq(image)
    end

    it "returns nil when attribute value not found" do
      proxy = Blanks::AssociationProxy.new("ProxyTestForm")
      image = ProxyTestForm.new(uuid: "abc-123", url: "test.jpg")
      proxy.push(image)

      found = proxy.find_by(:uuid, "not-found")

      expect(found).to be_nil
    end

    it "uses id cache when finding by id" do
      proxy = Blanks::AssociationProxy.new("ProxyTestForm")
      image = ProxyTestForm.new(id: 1, url: "test.jpg")
      proxy.push(image)

      found = proxy.find_by(:id, 1)

      expect(found).to eq(image)
    end
  end
end
