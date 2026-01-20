# frozen_string_literal: true

module Standard
  class PostsController < ApplicationController
    before_action :set_post, only: [:show, :edit, :update, :destroy]

    def index
      @posts = Post.all.order(created_at: :desc)
    end

    def show
    end

    def new
      @form = PostForm.new
    end

    def create
      @form = PostForm.new(post_params)

      if @form.valid?
        @post = Post.create!(@form.assignable_attributes)
        redirect_to standard_post_path(@post), notice: "post created"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @form = PostForm.from_model(@post)
    end

    def update
      @form = PostForm.new(post_params)

      if @form.valid?
        @post.update!(@form.assignable_attributes)
        redirect_to standard_post_path(@post), notice: "post updated"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @post.destroy!
      redirect_to standard_posts_path, notice: "post deleted"
    end

    private

    def set_post
      @post = Post.find(params[:id])
    end

    def post_params
      params.require(:post).permit(:title, :content, :published)
    end
  end
end
