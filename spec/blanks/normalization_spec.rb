# frozen_string_literal: true

require "spec_helper"

RSpec.describe Blanks::Normalization do
  let(:form_class) do
    Class.new(Blanks::Base) do
      attribute :email, :string
      attribute :phone, :string
      attribute :name, :string
    end
  end

  describe ".normalizes" do
    describe "with proc normalizer" do
      it "applies normalization on assignment" do
        form_class.normalizes :email, with: ->(email) { email.strip.downcase }
        form = form_class.new(email: " TEST@EXAMPLE.COM ")

        expect(form.email).to eq("test@example.com")
      end

      it "is idempotent when applied multiple times" do
        form_class.normalizes :email, with: ->(email) { email.strip.downcase }
        form = form_class.new(email: " TEST@EXAMPLE.COM ")

        form.email = form.email
        form.email = form.email

        expect(form.email).to eq("test@example.com")
      end

      it "applies normalization on re-assignment" do
        form_class.normalizes :email, with: ->(email) { email.strip.downcase }
        form = form_class.new(email: "test@example.com")

        form.email = " UPDATED@EXAMPLE.COM "

        expect(form.email).to eq("updated@example.com")
      end
    end

    describe "with symbol normalizer" do
      it "calls the method on the value" do
        form_class.normalizes :email, with: :downcase
        form = form_class.new(email: "TEST@EXAMPLE.COM")

        expect(form.email).to eq("test@example.com")
      end
    end

    describe "with multiple attributes" do
      it "applies normalization to all specified attributes" do
        form_class.normalizes :email, :name, with: ->(value) { value.strip.downcase }
        form = form_class.new(email: " TEST@EXAMPLE.COM ", name: " JOHN DOE ")

        expect(form.email).to eq("test@example.com")
        expect(form.name).to eq("john doe")
      end
    end

    describe "with apply_to_nil: false" do
      it "does not apply normalization to nil values" do
        form_class.normalizes :email, with: ->(email) { email.strip.downcase }
        form = form_class.new(email: nil)

        expect(form.email).to be_nil
      end
    end

    describe "with apply_to_nil: true" do
      it "applies normalization to nil values" do
        form_class.normalizes :email, with: ->(email) { email || "default@example.com" }, apply_to_nil: true
        form = form_class.new(email: nil)

        expect(form.email).to eq("default@example.com")
      end
    end

    describe "complex normalization" do
      it "handles chained operations" do
        form_class.normalizes :phone, with: ->(phone) { phone.delete("^0-9").delete_prefix("1") }
        form = form_class.new(phone: "1-555-123-4567")

        expect(form.phone).to eq("5551234567")
      end

      it "is idempotent for complex normalizations" do
        form_class.normalizes :phone, with: ->(phone) { phone.delete("^0-9").delete_prefix("1") }
        form = form_class.new(phone: "1-555-123-4567")

        form.phone = form.phone
        form.phone = form.phone

        expect(form.phone).to eq("5551234567")
      end
    end

    describe "integration with assign_attributes" do
      it "applies normalization when using assign_attributes" do
        form_class.normalizes :email, with: ->(email) { email.strip.downcase }
        form = form_class.new

        form.assign_attributes(email: " TEST@EXAMPLE.COM ")

        expect(form.email).to eq("test@example.com")
      end
    end

    describe "integration with from_model" do
      it "applies normalization when loading from model" do
        model = Struct.new(:email).new(" TEST@EXAMPLE.COM ")
        form_class.normalizes :email, with: ->(email) { email.strip.downcase }
        form = form_class.new

        form.from_model(model)

        expect(form.email).to eq("test@example.com")
      end
    end
  end
end
