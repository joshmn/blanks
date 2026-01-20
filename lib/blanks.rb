# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/array/extract_options"
require "active_support/core_ext/object/blank"

require "blanks/version"
require "blanks/association_proxy"
require "blanks/model_naming"
require "blanks/normalization"
require "blanks/associations"
require "blanks/nested_attributes"
require "blanks/base"

module Blanks
  class Error < StandardError; end
end
