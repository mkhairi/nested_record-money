# frozen_string_literal: true

module NestedRecord::Money::AccessorsDelegation
  private

  def delegate_macro(macro, args, kwargs)
    return super unless macro == :monetize

    attr_name = args.first
    currency_name = kwargs[:with] || :"#{attr_name}_currency"

    # Delegate the money attribute
    delegate(attr_name)
    delegate1("#{attr_name}=")

    # Delegate currency attribute unless disabled
    unless kwargs[:with] == false
      delegate(currency_name)
      delegate1("#{currency_name}=")
    end
  end
end
