# frozen_string_literal: true

module Blanks
  class AssociationProxy
    include Enumerable

    def initialize(class_name)
      @class_name = class_name
      @records = []
      @records_by_id = {}
    end

    def new(attributes = {})
      form_class = @class_name.constantize
      instance = form_class.new(attributes)
      push(instance)
      instance
    end

    def build(attributes = {})
      new(attributes)
    end

    def find_by_id(id)
      @records_by_id[id.to_s]
    end

    def find_by(attribute, value)
      return @records_by_id[value.to_s] if attribute.to_s == "id" && @records_by_id.key?(value.to_s)

      @records.find do |record|
        record.respond_to?(attribute) && record.public_send(attribute).to_s == value.to_s
      end
    end

    def push(record)
      @records << record
      if record.respond_to?(:id) && record.id.present?
        @records_by_id[record.id.to_s] = record
      end
      self
    end
    alias_method :<<, :push

    def each(&block)
      @records.each(&block)
    end

    def size
      @records.size
    end
    alias_method :length, :size
    alias_method :count, :size

    def empty?
      @records.empty?
    end

    def any?
      @records.any?
    end

    def [](index)
      @records[index]
    end

    def clear
      @records.clear
      @records_by_id.clear
    end

    def to_a
      @records
    end

    def to_ary
      @records
    end

    def persisted?
      false
    end

    def valid?
      @records.all?(&:valid?)
    end

    def errors
      @records.flat_map(&:errors)
    end
  end
end
