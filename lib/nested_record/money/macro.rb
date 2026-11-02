# frozen_string_literal: true

module NestedRecord::Money::Macro
  def monetize(*fields)
    options = fields.extract_options!
    raise ArgumentError, "monetize takes one field on a nested record, got #{fields.inspect}" unless fields.one?

    name = fields.first
    currency = options.delete(:currency)
    default = options.delete(:default)
    options.assert_valid_keys(:with)

    attribute_name = name.to_s
    currency_name = options[:with] || :"#{attribute_name}_currency"

    # Define the money attribute with custom type
    attribute_options = {}
    attribute_options[:default] = -> { default } if default

    attribute attribute_name, NestedRecord::Type::Monetize.new(currency: currency, currency_attribute: currency_name, default: default, **options), **attribute_options
    validates_with NestedRecord::Money::CastValidator, attributes: [attribute_name]

    # Define currency attribute if not explicitly disabled
    unless options[:with] == false || (respond_to?(:has_attribute?) && has_attribute?(currency_name))
      attribute currency_name, :string, default: -> { currency&.to_s || ::Money.default_currency.to_s }
    end

    # Override the setter to handle currency updates and keep the raw input for
    # CastValidator. instantiate skips the setter, so a stored null stays valid.
    define_method "#{attribute_name}=" do |value|
      instance_variable_set(:"@#{attribute_name}_before_type_cast", value)
      super(value)
      if value.is_a?(::Money) && respond_to?("#{currency_name}=")
        send("#{currency_name}=", value.currency.to_s)
      end
    end
  end
end
