# frozen_string_literal: true

module Standard
  class ArticlesController < ApplicationController
    before_action :set_article, only: [:show, :edit, :update, :destroy]

    def index
      @articles = Article.includes(:cover_image, :tags).order(created_at: :desc)
    end

    def show
    end

    def new
      @form = ArticleForm.new
      @form.build_cover_image
      3.times { @form.tags.new }
    end

    def create
      @form = ArticleForm.new(article_params)

      if @form.valid?
        @article = Article.create!(@form.assignable_attributes)
        redirect_to standard_article_path(@article), notice: "article created"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @form = ArticleForm.from_model(@article)
    end

    def update
      @form = ArticleForm.new(article_params)

      if @form.valid?
        @article.update!(@form.assignable_attributes)
        redirect_to standard_article_path(@article), notice: "article updated"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @article.destroy!
      redirect_to standard_articles_path, notice: "article deleted"
    end

    private

    def set_article
      @article = Article.find(params[:id])
    end

    def article_params
      params.require(:article).permit(
        :title, :body, :author_name,
        cover_image_attributes: [:id, :url, :alt_text, :_destroy],
        tags_attributes: [:id, :name, :color, :_destroy]
      )
    end
  end
end
