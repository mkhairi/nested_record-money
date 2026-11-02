# frozen_string_literal: true

# Adds not_a_number when a non-blank input cast to nil, like money-rails does.
# Blank input stays nil with no error; add `presence: true` to refuse it.
class NestedRecord::Money::CastValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value.nil?

    raw = record.instance_variable_get(:"@#{attribute}_before_type_cast")
    record.errors.add(attribute, :not_a_number, value: raw) if raw.present?
  end
end
