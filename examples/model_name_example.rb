# frozen_string_literal: true

require "blanks"

class PostForm < Blanks::Base
  attribute :id, :integer
  attribute :title, :string
end

class AdminArticleForm < Blanks::Base
  model_name_for :article

  attribute :id, :integer
  attribute :title, :string
end

form1 = PostForm.new
puts "postform model_name: #{form1.model_name}"
puts "postform model_name.param_key: #{form1.model_name.param_key}"
puts "postform persisted?: #{form1.persisted?}"
puts "postform to_param: #{form1.to_param.inspect}"

form2 = PostForm.new(id: 123, title: "hello")
puts "\npostform with id model_name: #{form2.model_name}"
puts "postform with id persisted?: #{form2.persisted?}"
puts "postform with id to_param: #{form2.to_param}"
puts "postform with id to_key: #{form2.to_key.inspect}"

form3 = AdminArticleForm.new
puts "\nadminarticleform model_name: #{form3.model_name}"
puts "adminarticleform model_name.param_key: #{form3.model_name.param_key}"
