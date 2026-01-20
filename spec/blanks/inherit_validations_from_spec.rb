# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Blanks::Base.inherit_validations_from" do
  before(:all) do
    @model_class = Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Validations

      attribute :id, :integer
      attribute :title, :string
      attribute :content, :string
      attribute :email, :string

      validates :title, presence: true
      validates :content, presence: true, length: { minimum: 10 }
      validates :email, format: { with: /\A[^@\s]+@[^@\s]+\z/ }

      def self.name
        "Post"
      end
    end

    @model_with_conditionals = Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Validations

      attribute :title, :string
      attribute :content, :string
      attribute :status, :string

      validates :title, presence: true
      validates :content, presence: true, if: -> { status == "published" }
      validates :status, presence: true, if: :published?

      def published?
        status == "published"
      end

      def self.name
        "ConditionalPost"
      end
    end
  end

  describe "with no options" do
    it "inherits all validators from model class" do
      model_class = @model_class
      form_class = Class.new(Blanks::Base) do
        model_name_for :test
        attribute :title, :string
        attribute :content, :string
        attribute :email, :string
        inherit_validations_from model_class
      end

      form = form_class.new
      form.valid?

      expect(form.errors[:title]).to include("can't be blank")
      expect(form.errors[:content]).to include("can't be blank")
    end

    it "preserves validator options" do
      model_class = @model_class
      form_class = Class.new(Blanks::Base) do
        model_name_for :test
        attribute :title, :string
        attribute :content, :string
        inherit_validations_from model_class, only: [:content]
      end

      form = form_class.new(content: "short")
      form.valid?

      expect(form.errors[:content]).to include("is too short (minimum is 10 characters)")
    end

    it "inherits format validators" do
      model_class = @model_class
      form_class = Class.new(Blanks::Base) do
        model_name_for :test
        attribute :email, :string
        inherit_validations_from model_class, only: [:email]
      end

      form = form_class.new(email: "invalid")
      form.valid?

      expect(form.errors[:email]).to include("is invalid")
    end
  end

  describe "with only: option" do
    it "inherits only specified validators" do
      model_class = @model_class
      form_class = Class.new(Blanks::Base) do
        model_name_for :test
        attribute :title, :string
        attribute :content, :string
        inherit_validations_from model_class, only: [:title]
      end

      form = form_class.new
      form.valid?

      expect(form.errors[:title]).to include("can't be blank")
      expect(form.errors[:content]).to be_empty
    end

    it "works with single attribute" do
      model_class = @model_class
      form_class = Class.new(Blanks::Base) do
        model_name_for :test
        attribute :title, :string
        inherit_validations_from model_class, only: :title
      end

      form = form_class.new
      form.valid?

      expect(form.errors[:title]).to include("can't be blank")
    end
  end

  describe "with except: option" do
    it "inherits all validators except specified ones" do
      model_class = @model_class
      form_class = Class.new(Blanks::Base) do
        model_name_for :test
        attribute :title, :string
        attribute :content, :string
        attribute :email, :string
        inherit_validations_from model_class, except: [:content, :email]
      end

      form = form_class.new
      form.valid?

      expect(form.errors[:title]).to include("can't be blank")
      expect(form.errors[:content]).to be_empty
      expect(form.errors[:email]).to be_empty
    end

    it "works with single attribute" do
      model_class = @model_class
      form_class = Class.new(Blanks::Base) do
        model_name_for :test
        attribute :title, :string
        attribute :content, :string
        inherit_validations_from model_class, except: [:content, :email]
      end

      form = form_class.new
      form.valid?

      expect(form.errors[:title]).to include("can't be blank")
      expect(form.errors[:content]).to be_empty
    end
  end

  describe "validation" do
    it "raises error when both only and except are specified" do
      model_class = @model_class
      expect {
        Class.new(Blanks::Base) do
          inherit_validations_from model_class, only: [:title], except: [:content]
        end
      }.to raise_error(ArgumentError, "cannot specify both :only and :except")
    end
  end

  describe "skipping unsafe validators" do
    it "skips validators with proc conditionals" do
      model_class = @model_with_conditionals
      form_class = Class.new(Blanks::Base) do
        model_name_for :test
        attribute :title, :string
        attribute :content, :string
        attribute :status, :string
        inherit_validations_from model_class
      end

      validators = form_class.validators.map { |v| [v.attributes, v.kind] }

      expect(validators).to include([[:title], :presence])
      expect(validators).to include([[:status], :presence])
      expect(validators).not_to include([[:content], :presence])
    end

    it "inherits validators with symbol conditionals" do
      model_class = @model_with_conditionals
      form_class = Class.new(Blanks::Base) do
        model_name_for :test
        attribute :status, :string
        inherit_validations_from model_class, only: [:status]

        def published?
          status == "published"
        end
      end

      form = form_class.new(status: nil)
      form.valid?
      expect(form.errors[:status]).to be_empty

      form_published = form_class.new(status: "published")
      form_published.instance_variable_set(:@status, nil)
      form_published.valid?
    end
  end

  describe "integration with inherit_attributes_from" do
    it "works with inherited attributes" do
      model_class = @model_class
      form_class = Class.new(Blanks::Base) do
        model_name_for :test
        inherit_attributes_from model_class, only: [:title, :content]
        inherit_validations_from model_class, only: [:title]
      end

      form = form_class.new
      form.valid?

      expect(form.errors[:title]).to include("can't be blank")
      expect(form.errors[:content]).to be_empty
    end
  end

  describe "multiple calls" do
    it "accumulates validators from multiple sources" do
      model_class = @model_class
      other_model = Class.new do
        include ActiveModel::Model
        include ActiveModel::Attributes
        include ActiveModel::Validations

        attribute :author, :string
        validates :author, presence: true
      end

      form_class = Class.new(Blanks::Base) do
        model_name_for :test
        attribute :title, :string
        attribute :author, :string
        inherit_validations_from model_class, only: [:title]
        inherit_validations_from other_model, only: [:author]
      end

      form = form_class.new
      form.valid?

      expect(form.errors[:title]).to include("can't be blank")
      expect(form.errors[:author]).to include("can't be blank")
    end
  end
end
