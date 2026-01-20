# frozen_string_literal: true

require "spec_helper"

RSpec.describe Blanks::ModelNaming do
  describe ".model_name" do
    it "strips Form suffix from class name" do
      form_class = Class.new(Blanks::Base)
      stub_const("PostForm", form_class)

      expect(PostForm.model_name.name).to eq("Post")
    end

    it "generates correct param_key" do
      form_class = Class.new(Blanks::Base)
      stub_const("PostForm", form_class)

      expect(PostForm.model_name.param_key).to eq("post")
    end

    it "generates correct route_key" do
      form_class = Class.new(Blanks::Base)
      stub_const("PostForm", form_class)

      expect(PostForm.model_name.route_key).to eq("posts")
    end

    it "handles class names without Form suffix" do
      form_class = Class.new(Blanks::Base)
      stub_const("Article", form_class)

      expect(Article.model_name.name).to eq("Article")
    end
  end

  describe ".model_name_for" do
    it "overrides the model name" do
      form_class = Class.new(Blanks::Base) do
        model_name_for :article
      end
      stub_const("AdminPostForm", form_class)

      expect(AdminPostForm.model_name.name).to eq("Article")
    end

    it "generates correct param_key from override" do
      form_class = Class.new(Blanks::Base) do
        model_name_for :article
      end
      stub_const("AdminPostForm", form_class)

      expect(AdminPostForm.model_name.param_key).to eq("article")
    end

    it "accepts symbol" do
      form_class = Class.new(Blanks::Base) do
        model_name_for :blog_post
      end

      expect(form_class.model_name.name).to eq("BlogPost")
    end

    it "accepts string" do
      form_class = Class.new(Blanks::Base) do
        model_name_for "blog_post"
      end

      expect(form_class.model_name.name).to eq("BlogPost")
    end
  end

  describe "#model_name" do
    it "delegates to class method" do
      form_class = Class.new(Blanks::Base)
      stub_const("PostForm", form_class)

      form = PostForm.new

      expect(form.model_name.name).to eq("Post")
    end
  end
end
