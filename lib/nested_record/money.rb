# frozen_string_literal: true

require 'nested_record'
require 'money-rails'

unless NestedRecord::MacroRecorder.respond_to?(:register)
  raise LoadError, 'nested_record-money needs NestedRecord::MacroRecorder.register ' \
                   '(gem "nested_record", github: "mkhairi/nested_record", branch: "extensions")'
end

module NestedRecord::Money
  require 'nested_record/money/version'
  require 'nested_record/money/cast_validator'
  require 'nested_record/money/macro'
  require 'nested_record/money/accessors_delegation'
end

require 'nested_record/type/monetize'

# ponytail: NestedRecord::Base only, so `include NestedRecord::Macro` on an
# ActiveRecord model keeps money-rails' own monetize for its columns.
NestedRecord::Base.extend(NestedRecord::Money::Macro)
NestedRecord::MacroRecorder.register(:monetize)
# Concern built its delegators from MACROS at load, before register ran.
NestedRecord::Concern.def_delegator :macro_recorder, :monetize
NestedRecord::NestedAccessorsSetup.prepend(NestedRecord::Money::AccessorsDelegation)
