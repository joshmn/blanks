# frozen_string_literal: true

module Blanks
  module Normalization
    extend ActiveSupport::Concern

    included do
      class_attribute :_normalizations, instance_writer: false, default: {}
    end

    class_methods do
      def normalizes(*names, with:, apply_to_nil: false)
        names.each do |name|
          _normalizations[name.to_s] = { normalizer: with, apply_to_nil: apply_to_nil }

          define_method("#{name}=") do |value|
            normalized_value = self.class.normalize_value_for(name, value)
            super(normalized_value)
          end
        end
      end

      def normalize_value_for(name, value)
        normalization = _normalizations[name.to_s]
        return value unless normalization

        return value if value.nil? && !normalization[:apply_to_nil]

        normalizer = normalization[:normalizer]
        if normalizer.respond_to?(:call)
          normalizer.call(value)
        else
          value.public_send(normalizer)
        end
      end
    end
  end
end
