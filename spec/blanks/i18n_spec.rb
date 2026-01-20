# frozen_string_literal: true

require "spec_helper"

RSpec.describe "I18n support" do
  it "provides human_attribute_name" do
    form_class = Class.new(Blanks::Base) do
      attribute :title, :string
    end
    stub_const("PostForm", form_class)

    expect(PostForm.human_attribute_name(:title)).to eq("Title")
  end

  it "uses model_name for translation lookup" do
    form_class = Class.new(Blanks::Base) do
      attribute :title, :string
    end
    stub_const("PostForm", form_class)

    expect(PostForm.model_name.i18n_key).to eq(:post)
  end

  it "supports custom translations via model_name_for" do
    form_class = Class.new(Blanks::Base) do
      model_name_for :article
      attribute :title, :string
    end
    stub_const("AdminPostForm", form_class)

    expect(AdminPostForm.model_name.i18n_key).to eq(:article)
  end
end
