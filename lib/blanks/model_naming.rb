# frozen_string_literal: true

module Blanks
  module ModelNaming
    extend ActiveSupport::Concern

    included do
      class_attribute :_model_name_override
    end

    class_methods do
      def model_name
        return _model_name_override if _model_name_override

        name_without_form = self.name.sub(/Form$/, '')
        ActiveModel::Name.new(self, nil, name_without_form)
      end

      def model_name_for(name)
        self._model_name_override = ActiveModel::Name.new(self, nil, name.to_s.camelize)
      end
    end
  end
end
