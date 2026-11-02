# frozen_string_literal: true

require 'nested_record'
require 'money-rails'

module NestedRecord::Money
  require 'nested_record/money/version'
  require 'nested_record/money/macro'
  require 'nested_record/money/accessors_delegation'
end

require 'nested_record/type/monetize'

# ponytail: NestedRecord::Base only, so `include NestedRecord::Macro` on an
# ActiveRecord model keeps money-rails' own monetize for its columns.
NestedRecord::Base.extend(NestedRecord::Money::Macro)
NestedRecord::MacroRecorder.register(:monetize)
NestedRecord::NestedAccessorsSetup.prepend(NestedRecord::Money::AccessorsDelegation)
