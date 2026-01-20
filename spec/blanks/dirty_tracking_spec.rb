# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Dirty tracking" do
  it "tracks attribute changes" do
    form_class = Class.new(Blanks::Base) do
      attribute :title, :string
    end

    form = form_class.new(title: "original")
    form.title = "changed"

    expect(form.title_changed?).to be(true)
  end

  it "tracks previous value" do
    form_class = Class.new(Blanks::Base) do
      attribute :title, :string
    end

    form = form_class.new(title: "original")
    form.title = "changed"

    expect(form.title_was).to eq("original")
  end

  it "provides changes hash" do
    form_class = Class.new(Blanks::Base) do
      attribute :title, :string
      attribute :content, :string
    end

    form = form_class.new(title: "original", content: "original content")
    form.title = "changed"

    expect(form.changes).to eq("title" => ["original", "changed"])
  end

  it "clears changes after assign_attributes" do
    form_class = Class.new(Blanks::Base) do
      attribute :title, :string
    end

    form = form_class.new(title: "original")
    form.title = "changed"
    form.assign_attributes(title: "new")

    expect(form.changed?).to be(false)
  end

  it "detects if any attributes changed" do
    form_class = Class.new(Blanks::Base) do
      attribute :title, :string
    end

    form = form_class.new(title: "original")

    expect(form.changed?).to be(false)
  end
end
