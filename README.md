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
- Integers cast as cents. Decimals and strings cast through `to_money`.
- `monetize` takes one field per call on a nested record.
- On an ActiveRecord model, `monetize` is money-rails' own.

## License

MIT
