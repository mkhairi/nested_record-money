# frozen_string_literal: true

require 'money'
require 'monetize'

class NestedRecord::Type
  class Monetize < ActiveModel::Type::Value
    include ActiveModel::Type::Helpers::Mutable

    def initialize(currency: nil, currency_attribute: nil, default: nil, **options)
      @currency = currency
      @currency_attribute = currency_attribute
      @default = default
      @options = options
      super()
    end

    def cast(value)
      return value if value.is_a?(::Money)
      
      # Handle default value when value is nil
      if value.nil?
        return cast(@default) if @default
        return nil
      end
      
      return nil if value == ''

      if value.is_a?(Hash)
        amount = value['amount'] || value[:amount] || value['cents'] || value[:cents]
        currency = value['currency'] || value[:currency] || value['currency_iso'] || value[:currency_iso] || @currency || ::Money.default_currency
        return ::Money.new(amount, currency) if amount
      else
        currency = @currency || ::Money.default_currency
        
        # For backward compatibility, treat integers as cents
        # For decimals, use monetize gem's to_money conversion (treats as dollars)
        if value.is_a?(Integer)
          return ::Money.new(value, currency)
        elsif value.is_a?(String)
          # Form input in major units. Monetize.parse reads "abc" as 0 and
          # "USD 12" as USD, so reject both instead of storing them.
          # ponytail: "US$12" still reads as MYR; reject any other letters if that matters.
          return nil unless value.match?(/\d/)

          money = ::Monetize.parse(value.upcase, currency, assume_from_symbol: true)
          return money if money&.currency == ::Money::Currency.wrap(currency)
        elsif value.respond_to?(:to_money)
          return value.to_money(currency)
        end
      end

      nil
    end

    def deserialize(value)
      return nil if value.nil?

      if value.is_a?(String)
        # A stored digit String reads as cents, like a stored Integer.
        cents = Integer(value, 10, exception: false)
        return cast(cents) if cents

        begin
          parsed = ActiveSupport::JSON.decode(value)
          return cast(parsed) if parsed.is_a?(Hash)
        rescue JSON::ParserError
          # Not JSON. Like a decoded non-Hash, it falls through to cast below.
        end
      end

      cast(value)
    end

    def serialize(value)
      return nil if value.nil?

      if value.is_a?(::Money)
        return {
          'cents' => value.cents,
          'currency_iso' => value.currency.to_s
        }
      end

      # If not a Money object, try to cast it first
      money_value = cast(value)
      if money_value
        {
          'cents' => money_value.cents,
          'currency_iso' => money_value.currency.to_s
        }
      else
        nil
      end
    end

    def changed_in_place?(raw_old_value, new_value)
      old_value = deserialize(raw_old_value)
      old_value != new_value
    end
  end
end
