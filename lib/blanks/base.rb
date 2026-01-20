# frozen_string_literal: true

require "active_model"

module Blanks
  class Base
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations
    include ActiveModel::Dirty
    include ActiveModel::Callbacks

    include Blanks::ModelNaming
    include Blanks::Normalization
    include Blanks::Associations
    include Blanks::NestedAttributes

    define_model_callbacks :validation

    def self.inherit_attributes_from(model_class, only: nil, except: nil)
      raise ArgumentError, "cannot specify both :only and :except" if only && except

      attribute_names = if model_class.respond_to?(:attribute_types)
        model_class.attribute_types.keys
      elsif model_class.respond_to?(:columns)
        model_class.columns.map(&:name)
      else
        raise ArgumentError, "#{model_class} does not respond to :attribute_types or :columns"
      end

      attribute_names = Array(only).map(&:to_s) if only
      attribute_names -= Array(except).map(&:to_s) if except

      attribute_names.each do |attr_name|
        next if attribute_types.key?(attr_name)

        attr_type = if model_class.respond_to?(:attribute_types)
          model_class.attribute_types[attr_name]
        elsif model_class.respond_to?(:columns)
          column = model_class.columns.find { |c| c.name == attr_name }
          column&.type
        end

        attribute attr_name.to_sym, attr_type&.type || :value
      end
    end

    def self.inherit_validations_from(model_class, only: nil, except: nil)
      raise ArgumentError, "cannot specify both :only and :except" if only && except

      model_class.validators.each do |validator|
        next if skip_validator?(validator)

        attrs = validator.attributes.dup
        attrs = attrs & Array(only).map(&:to_sym) if only
        attrs = attrs - Array(except).map(&:to_sym) if except
        next if attrs.empty?

        options = validator.options.except(:class)
        kind = validator.kind

        if options.empty?
          validates(*attrs, kind => true)
        else
          validates(*attrs, kind => options)
        end
      end
    end

    def self.skip_validator?(validator)
      if defined?(ActiveRecord::Validations::AssociatedValidator)
        return true if validator.is_a?(ActiveRecord::Validations::AssociatedValidator)
      end

      opts = validator.options
      [:if, :unless].any? { |key| opts[key].is_a?(Proc) }
    end
    private_class_method :skip_validator?

    def self.from_model(model)
      instance = new
      instance.from_model(model)
      instance
    end

    def initialize(attributes = {})
      super()
      @marked_for_destruction = false
      assign_attributes(attributes) if attributes.present?
    end

    def assign_attributes(new_attributes)
      return if new_attributes.blank?

      attrs = if new_attributes.respond_to?(:to_unsafe_h)
        new_attributes.to_unsafe_h.stringify_keys
      elsif new_attributes.respond_to?(:to_h)
        new_attributes.to_h.stringify_keys
      else
        new_attributes.stringify_keys
      end

      attrs.each do |key, value|
        if key.end_with?("_attributes")
          association_name = key.delete_suffix("_attributes")
          send("#{association_name}_attributes=", value)
        elsif key == "_destroy"
          self._destroy = value
        else
          public_send("#{key}=", value)
        end
      end

      changes_applied
    end

    def from_model(model)
      return self if model.nil?

      self.class.attribute_names.each do |attr_name|
        if model.respond_to?(attr_name)
          public_send("#{attr_name}=", model.public_send(attr_name))
        end
      end

      self.class.associations.each do |name, association|
        next unless model.respond_to?(name)

        associated_value = model.public_send(name)
        next if associated_value.nil?

        case association[:type]
        when :has_one
          form_instance = association[:class_name].constantize.new
          form_instance.from_model(associated_value)
          public_send("#{name}=", form_instance)
        when :has_many
          associated_value.each do |record|
            form_instance = association[:class_name].constantize.new
            form_instance.from_model(record)
            public_send(name).push(form_instance)
          end
        end
      end

      self
    end

    def persisted?
      respond_to?(:id) && id.present?
    end

    def to_key
      persisted? ? [id] : nil
    end

    def to_param
      persisted? ? id.to_s : nil
    end

    def to_model
      self
    end

    def marked_for_destruction?
      @marked_for_destruction
    end

    def mark_for_destruction
      @marked_for_destruction = true
    end

    def _destroy
      @marked_for_destruction
    end

    def _destroy=(value)
      @marked_for_destruction = ActiveModel::Type::Boolean.new.cast(value)
    end

    def valid?(context = nil)
      run_callbacks :validation do
        super(context) && nested_forms_valid?
      end
    end

    def model_attributes
      attribute_names.each_with_object({}) do |name, hash|
        hash[name] = public_send(name)
      end
    end

    def attributes
      attrs = model_attributes.dup

      self.class.associations.each do |name, association|
        nested_form = public_send(name)
        next if nested_form.nil?

        case association[:type]
        when :has_one
          nested_attrs = nested_form.attributes
          nested_attrs["_destroy"] = true if nested_form.marked_for_destruction?
          attrs["#{name}_attributes"] = nested_attrs
        when :has_many
          attrs["#{name}_attributes"] = nested_form.map do |form|
            form_attrs = form.attributes
            form_attrs["_destroy"] = true if form.marked_for_destruction?
            form_attrs
          end
        end
      end

      attrs
    end

    def assignable_attributes(exclude: [:id])
      excluded_keys = Array(exclude).map(&:to_s)
      attributes.except(*excluded_keys)
    end

    private

    def nested_forms_valid?
      self.class.associations.all? do |name, association|
        nested_form = public_send(name)
        next true if nested_form.nil?

        case association[:type]
        when :has_one
          if nested_form.valid?
            true
          else
            copy_nested_errors(name, nested_form)
            false
          end
        when :has_many
          if nested_form.valid?
            true
          else
            nested_form.each_with_index do |form, index|
              copy_nested_errors("#{name}[#{index}]", form) unless form.valid?
            end
            false
          end
        end
      end
    end

    def copy_nested_errors(association_name, nested_form)
      nested_form.errors.each do |error|
        errors.add("#{association_name}.#{error.attribute}", error.message)
      end
    end
  end
end
