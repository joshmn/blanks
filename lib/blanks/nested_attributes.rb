# frozen_string_literal: true

module Blanks
  module NestedAttributes
    extend ActiveSupport::Concern

    included do
      class_attribute :nested_attributes_options, default: {}
    end

    class_methods do
      def accepts_nested_attributes_for(*attr_names)
        options = attr_names.extract_options!

        attr_names.each do |association_name|
          self.nested_attributes_options = nested_attributes_options.merge(
            association_name.to_s => options
          )

          define_nested_attributes_method(association_name)
        end
      end

      private

      def define_nested_attributes_method(association_name)
        define_method("#{association_name}_attributes=") do |attributes|
          association = self.class.associations[association_name.to_s]

          unless association
            raise ArgumentError, "No association found for name '#{association_name}'"
          end

          case association[:type]
          when :has_one
            assign_nested_attributes_for_one_to_one_association(association_name, attributes)
          when :has_many
            assign_nested_attributes_for_collection_association(association_name, attributes)
          end
        end
      end
    end

    private

    def assign_nested_attributes_for_one_to_one_association(association_name, attributes)
      return if attributes.blank?

      association = self.class.associations[association_name.to_s]
      options = self.class.nested_attributes_options[association_name.to_s] || {}
      form_class = association[:class_name].constantize
      attrs_hash = attributes.stringify_keys

      if has_destroy_flag?(attrs_hash) && options[:allow_destroy]
        instance = public_send(association_name)
        instance&.mark_for_destruction
        return
      end

      instance = public_send(association_name)
      attrs_without_destroy = attrs_hash.except("_destroy")
      if instance
        instance.assign_attributes(attrs_without_destroy)
      else
        instance = form_class.new(attrs_without_destroy)
        public_send("#{association_name}=", instance)
      end
    end

    def assign_nested_attributes_for_collection_association(association_name, attributes)
      return if attributes.blank?

      attributes_collection = attributes.is_a?(Hash) ? attributes.values : attributes
      association = self.class.associations[association_name.to_s]
      options = self.class.nested_attributes_options[association_name.to_s] || {}
      form_class = association[:class_name].constantize
      collection = public_send(association_name)
      primary_key = (options[:primary_key] || association[:primary_key] || "id").to_s

      attributes_collection.each do |attrs|
        next if call_reject_if(association_name, attrs)

        attrs_hash = attrs.is_a?(Hash) ? attrs.stringify_keys : attrs

        if has_destroy_flag?(attrs_hash)
          if options[:allow_destroy] && attrs_hash[primary_key].present?
            existing = collection.find_by(primary_key, attrs_hash[primary_key])
            if existing
              existing.mark_for_destruction
            else
              new_form = collection.new(attrs_hash.except("_destroy"))
              new_form.mark_for_destruction
            end
          end
          next
        end

        if attrs_hash[primary_key].present?
          existing = collection.find_by(primary_key, attrs_hash[primary_key])
          if existing
            existing.assign_attributes(attrs_hash.except(primary_key, "_destroy"))
          else
            collection.new(attrs_hash.except("_destroy"))
          end
        else
          collection.new(attrs_hash.except("_destroy"))
        end
      end
    end

    def call_reject_if(association_name, attributes)
      options = self.class.nested_attributes_options[association_name.to_s]
      return false unless options

      reject_if = options[:reject_if]
      return false unless reject_if

      if reject_if.is_a?(Symbol)
        method(reject_if).call(attributes)
      else
        reject_if.call(attributes)
      end
    end

    def has_destroy_flag?(attributes)
      attrs = attributes.stringify_keys
      value = attrs["_destroy"]
      ActiveModel::Type::Boolean.new.cast(value)
    end
  end
end
