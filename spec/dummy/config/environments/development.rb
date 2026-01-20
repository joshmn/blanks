# frozen_string_literal: true

Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true
  config.active_storage.service = :local
  config.secret_key_base = "dev_secret_key_base_for_dummy_app_only"
end
