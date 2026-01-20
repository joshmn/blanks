# frozen_string_literal: true

require "spec_helper"

RSpec.describe Blanks::AssociationProxy do
  let(:form_class) do
    Class.new(Blanks::Base) do
      attribute :url, :string
    end
  end

  before do
    stub_const("ItemForm", form_class)
  end

  describe "#new" do
    it "creates a new form instance" do
      proxy = described_class.new("ItemForm")

      item = proxy.new(url: "https://example.com")

      expect(item).to be_a(ItemForm)
    end

    it "adds the instance to the collection" do
      proxy = described_class.new("ItemForm")

      proxy.new(url: "https://example.com")

      expect(proxy.count).to eq(1)
    end

    it "passes attributes to the form" do
      proxy = described_class.new("ItemForm")

      item = proxy.new(url: "https://example.com")

      expect(item.url).to eq("https://example.com")
    end
  end

  describe "#build" do
    it "is an alias for new" do
      proxy = described_class.new("ItemForm")

      item = proxy.build(url: "https://example.com")

      expect(item).to be_a(ItemForm)
    end
  end

  describe "#push" do
    it "adds a record to the collection" do
      proxy = described_class.new("ItemForm")
      item = ItemForm.new(url: "https://example.com")

      proxy.push(item)

      expect(proxy.count).to eq(1)
    end

    it "returns self for chaining" do
      proxy = described_class.new("ItemForm")
      item = ItemForm.new(url: "https://example.com")

      result = proxy.push(item)

      expect(result).to eq(proxy)
    end
  end

  describe "#<<" do
    it "is an alias for push" do
      proxy = described_class.new("ItemForm")
      item = ItemForm.new(url: "https://example.com")

      proxy << item

      expect(proxy.count).to eq(1)
    end
  end

  describe "#each" do
    it "iterates over the collection" do
      proxy = described_class.new("ItemForm")
      proxy.new(url: "first")
      proxy.new(url: "second")

      urls = []
      proxy.each { |item| urls << item.url }

      expect(urls).to eq(["first", "second"])
    end
  end

  describe "#size" do
    it "returns the number of items" do
      proxy = described_class.new("ItemForm")
      proxy.new(url: "first")
      proxy.new(url: "second")

      expect(proxy.size).to eq(2)
    end
  end

  describe "#count" do
    it "is an alias for size" do
      proxy = described_class.new("ItemForm")
      proxy.new(url: "first")

      expect(proxy.count).to eq(1)
    end
  end

  describe "#length" do
    it "is an alias for size" do
      proxy = described_class.new("ItemForm")
      proxy.new(url: "first")

      expect(proxy.length).to eq(1)
    end
  end

  describe "#empty?" do
    it "returns true when collection is empty" do
      proxy = described_class.new("ItemForm")

      expect(proxy.empty?).to be(true)
    end

    it "returns false when collection has items" do
      proxy = described_class.new("ItemForm")
      proxy.new(url: "first")

      expect(proxy.empty?).to be(false)
    end
  end

  describe "#any?" do
    it "returns false when collection is empty" do
      proxy = described_class.new("ItemForm")

      expect(proxy.any?).to be(false)
    end

    it "returns true when collection has items" do
      proxy = described_class.new("ItemForm")
      proxy.new(url: "first")

      expect(proxy.any?).to be(true)
    end
  end

  describe "#[]" do
    it "returns item at index" do
      proxy = described_class.new("ItemForm")
      proxy.new(url: "first")
      proxy.new(url: "second")

      expect(proxy[1].url).to eq("second")
    end
  end

  describe "#clear" do
    it "removes all items from collection" do
      proxy = described_class.new("ItemForm")
      proxy.new(url: "first")
      proxy.new(url: "second")

      proxy.clear

      expect(proxy.count).to eq(0)
    end
  end

  describe "#to_a" do
    it "returns the underlying array" do
      proxy = described_class.new("ItemForm")
      item1 = proxy.new(url: "first")
      item2 = proxy.new(url: "second")

      expect(proxy.to_a).to eq([item1, item2])
    end
  end

  describe "#valid?" do
    it "returns true when all items are valid" do
      valid_form_class = Class.new(Blanks::Base) do
        attribute :url, :string
        validates :url, presence: true
      end
      stub_const("ValidForm", valid_form_class)

      proxy = described_class.new("ValidForm")
      proxy.new(url: "https://example.com")

      expect(proxy.valid?).to be(true)
    end

    it "returns false when any item is invalid" do
      valid_form_class = Class.new(Blanks::Base) do
        attribute :url, :string
        validates :url, presence: true
      end
      stub_const("ValidForm", valid_form_class)

      proxy = described_class.new("ValidForm")
      proxy.new(url: "https://example.com")
      proxy.new(url: nil)

      expect(proxy.valid?).to be(false)
    end
  end
end
