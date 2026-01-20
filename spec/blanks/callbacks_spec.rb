# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Callbacks" do
  it "runs before_validation callback" do
    form_class = Class.new(Blanks::Base) do
      attribute :title, :string
      before_validation :normalize_title

      def normalize_title
        self.title = title&.strip&.downcase
      end
    end

    form = form_class.new(title: "  HELLO  ")
    form.valid?

    expect(form.title).to eq("hello")
  end

  it "runs after_validation callback" do
    callback_ran = false

    form_class = Class.new(Blanks::Base) do
      attribute :title, :string
      validates :title, presence: true

      after_validation do
        callback_ran = true
      end

      define_method(:callback_ran=) { |value| callback_ran = value }
    end

    form = form_class.new(title: "test")
    form.valid?

    expect(callback_ran).to be(true)
  end

  it "runs around_validation callback" do
    form_class = Class.new(Blanks::Base) do
      attribute :title, :string
      attribute :validated, :boolean, default: false

      around_validation :mark_validated

      def mark_validated
        self.validated = true
        yield
      end
    end

    form = form_class.new(title: "test")
    form.valid?

    expect(form.validated).to be(true)
  end
end
