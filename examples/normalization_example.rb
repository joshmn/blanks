# frozen_string_literal: true

require "blanks"

class UserForm < Blanks::Base
  attribute :email, :string
  attribute :phone, :string
  attribute :username, :string

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :phone, with: ->(phone) { phone.delete("^0-9").delete_prefix("1") }
  normalizes :username, with: :downcase
end

puts "email normalization"
form = UserForm.new(email: " CRUISE-CONTROL@EXAMPLE.COM\n")
puts "input: ' CRUISE-CONTROL@EXAMPLE.COM\\n'"
puts "normalized: #{form.email.inspect}"
puts

puts "phone normalization"
form = UserForm.new(phone: "1-555-123-4567")
puts "input: '1-555-123-4567'"
puts "normalized: #{form.phone.inspect}"
puts

puts "symbol normalizer"
form = UserForm.new(username: "JohnDoe")
puts "input: 'JohnDoe'"
puts "normalized: #{form.username.inspect}"
puts

puts "idempotency test"
form = UserForm.new(email: " TEST@EXAMPLE.COM ")
puts "initial: #{form.email.inspect}"
form.email = form.email
puts "after reassignment: #{form.email.inspect}"
form.email = form.email
puts "after second reassignment: #{form.email.inspect}"
