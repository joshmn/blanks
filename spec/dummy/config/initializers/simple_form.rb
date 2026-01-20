# frozen_string_literal: true

SimpleForm.setup do |config|
  config.button_class = "btn"
  config.default_wrapper = :default
  config.boolean_style = :inline

  config.wrappers :default, class: :input, hint_class: :hint, error_class: :error do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label
    b.use :input
    b.use :error, wrap_with: { tag: :span, class: :error }
    b.use :hint, wrap_with: { tag: :span, class: :hint }
  end
end
