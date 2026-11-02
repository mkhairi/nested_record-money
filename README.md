# nested_record-money

money-rails `monetize` for [nested_record](https://github.com/mkhairi/nested_record) attributes.

## Installation

```ruby
gem "nested_record", github: "mkhairi/nested_record", branch: "extensions"
gem "nested_record-money", github: "mkhairi/nested_record-money"
```

Requires the nested_record extension hooks (`MacroRecorder.register`, `NestedAccessorsSetup#delegate_macro`).

## Usage

```ruby
class Payment < ApplicationRecord
  include NestedRecord::Macro

  monetize :amount_cents # money-rails, unchanged

  has_one_nested :fees do
    monetize :gateway_fee, default: 0
    monetize :tenant_fee, currency: "MYR", with: :tenant_fee_currency
  end

  nested_accessors from: :pricing do
    monetize :cost, with: false # no currency attribute
  end
end
```

- Options: `currency:`, `default:`, `with:` (currency attribute name, `false` for none).
- Stored as `{ "cents" => 1500, "currency_iso" => "MYR" }`.
- Units: an Integer is cents (`default: 30` is 0.30). A String is major units (form input `"0.30"` is 0.30). A Float or BigDecimal is major units.
- A String with no digits, one Monetize cannot parse, or one naming another currency (`"USD 12"` on a MYR attribute) casts to `nil`. The record then fails validation with `not_a_number`, so the form shows an error instead of storing a silent value.
- A blank String casts to `nil` with no error. Add `validates :fee, presence: true` inside the nested block to refuse it.
- A stored `null` reads as `nil` and stays valid. A missing key reads as `default:`.
- A stored digit String (`"1500"`) reads as cents, like a stored Integer.
- `with:` mirrors the currency of an assigned `Money` only. Casting uses `currency:` or `Money.default_currency`.
- Unknown options raise `ArgumentError`. money-rails options such as `with_currency:` or `allow_nil:` are not supported.
- `monetize` takes one field per call on a nested record.
- On an ActiveRecord model, `monetize` is money-rails' own.

## License

MIT
