# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Blanks::Base.inherit_attributes_from" do
  before(:all) do
    @model_class = Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :id, :integer
      attribute :title, :string
      attribute :content, :string
      attribute :published_at, :datetime
      attribute :view_count, :integer
      attribute :created_at, :datetime
      attribute :updated_at, :datetime

      def self.name
        "Post"
      end
    end
  end

  describe "with no options" do
    it "inherits all attributes from model class" do
      model_class = @model_class
      form_class = Class.new(Blanks::Base) do
        inherit_attributes_from model_class
      end

      expect(form_class.attribute_names).to include("id", "title", "content", "published_at", "view_count", "created_at", "updated_at")
    end

    it "preserves attribute types from model class" do
      model_class = @model_class
      form_class = Class.new(Blanks::Base) do
        inherit_attributes_from model_class
      end

      form = form_class.new(title: "test", view_count: "42")

      expect(form.title).to eq("test")
      expect(form.view_count).to eq(42)
    end
  end

  describe "with only: option" do
    it "inherits only specified attributes" do
      model_class = @model_class
      form_class = Class.new(Blanks::Base) do
        inherit_attributes_from model_class, only: [:title, :content]
      end

      expect(form_class.attribute_names).to include("title", "content")
      expect(form_class.attribute_names).not_to include("id", "created_at", "updated_at")
    end

    it "works with single attribute" do
      model_class = @model_class
      form_class = Class.new(Blanks::Base) do
        inherit_attributes_from model_class, only: :title
      end

      expect(form_class.attribute_names).to eq(["title"])
    end
  end

  describe "with except: option" do
    it "inherits all attributes except specified ones" do
      model_class = @model_class
      form_class = Class.new(Blanks::Base) do
        inherit_attributes_from model_class, except: [:created_at, :updated_at]
      end

      expect(form_class.attribute_names).to include("id", "title", "content", "published_at", "view_count")
      expect(form_class.attribute_names).not_to include("created_at", "updated_at")
    end

    it "works with single attribute" do
      model_class = @model_class
      form_class = Class.new(Blanks::Base) do
        inherit_attributes_from model_class, except: :id
      end

      expect(form_class.attribute_names).to include("title", "content")
      expect(form_class.attribute_names).not_to include("id")
    end
  end

  describe "validation" do
    it "raises error when both only and except are specified" do
      model_class = @model_class
      expect {
        Class.new(Blanks::Base) do
          inherit_attributes_from model_class, only: [:title], except: [:id]
        end
      }.to raise_error(ArgumentError, "cannot specify both :only and :except")
    end

    it "raises error when model class does not respond to attribute_types or columns" do
      invalid_class = Class.new

      expect {
        Class.new(Blanks::Base) do
          inherit_attributes_from invalid_class
        end
      }.to raise_error(ArgumentError, /does not respond to :attribute_types or :columns/)
    end
  end

  describe "integration with existing attributes" do
    it "does not override existing attribute definitions" do
      model_class = @model_class
      form_class = Class.new(Blanks::Base) do
        attribute :title, :integer
        inherit_attributes_from model_class, only: [:title, :content]
      end

      expect(form_class.attribute_types["title"].type).to eq(:integer)
    end

    it "adds new attributes alongside existing ones" do
      model_class = @model_class
      form_class = Class.new(Blanks::Base) do
        attribute :custom_field, :string
        inherit_attributes_from model_class, only: [:title, :content]
      end

      expect(form_class.attribute_names).to include("custom_field", "title", "content")
    end
  end

  describe "integration with from_model" do
    it "loads values from model for inherited attributes" do
      model_class = @model_class
      form_class = Class.new(Blanks::Base) do
        inherit_attributes_from model_class, only: [:title, :content]
      end

      model = model_class.new(title: "Test Post", content: "Test Content")
      form = form_class.from_model(model)

      expect(form.title).to eq("Test Post")
      expect(form.content).to eq("Test Content")
    end
  end
end
