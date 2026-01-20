# frozen_string_literal: true

module Blanks
  module Associations
    extend ActiveSupport::Concern

    included do
      class_attribute :associations, default: {}
    end

    class_methods do
      def has_one(name, class_name: nil, primary_key: :id, **options)
        association_class_name = class_name || "#{name.to_s.camelize}Form"

        self.associations = associations.merge(
          name.to_s => { type: :has_one, class_name: association_class_name, primary_key: primary_key.to_s }
        )

        attr_reader name

        define_method("#{name}=") do |value|
          instance_variable_set("@#{name}", value)
        end

        define_method("build_#{name}") do |attributes = {}|
          form_class = association_class_name.constantize
          instance = form_class.new(attributes)
          instance_variable_set("@#{name}", instance)
          instance
        end

        accepts_nested_attributes_for(name, primary_key: primary_key, **options)
      end

      def has_many(name, class_name: nil, primary_key: :id, **options)
        association_class_name = class_name || "#{name.to_s.singularize.camelize}Form"

        self.associations = associations.merge(
          name.to_s => { type: :has_many, class_name: association_class_name, primary_key: primary_key.to_s }
        )

        define_method(name) do
          ivar = "@#{name}"
          unless instance_variable_defined?(ivar)
            instance_variable_set(ivar, AssociationProxy.new(association_class_name))
          end
          instance_variable_get(ivar)
        end

        define_method("#{name}=") do |value|
          instance_variable_set("@#{name}", value)
        end

        accepts_nested_attributes_for(name, primary_key: primary_key, **options)
      end
    end
  end
end
