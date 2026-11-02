require 'spec_helper'

RSpec.describe NestedRecord::Type::Monetize do
  around do |example|
    previous = Money.default_currency
    Money.default_currency = 'MYR'
    example.run
  ensure
    Money.default_currency = previous
  end

  subject(:type) { described_class.new(currency: 'MYR') }

  describe '#cast' do
    it 'reads an Integer as cents' do
      expect(type.cast(30)).to eq(Money.new(30, 'MYR'))
    end

    it 'reads a String as ringgit' do
      expect(type.cast('0.30')).to eq(Money.new(30, 'MYR'))
      expect(type.cast('1,000.00')).to eq(Money.new(100_000, 'MYR'))
    end

    it 'returns nil for a String with no digits' do
      expect(type.cast('abc')).to be_nil
      expect(type.cast(' ')).to be_nil
    end

    it 'returns nil when a String names another currency' do
      expect(type.cast('USD 12')).to be_nil
    end

    it 'returns nil for a lowercase code or a foreign symbol' do
      expect(type.cast('usd 12')).to be_nil
      expect(type.cast('12 sgd')).to be_nil
      expect(type.cast('$12')).to be_nil
    end

    it 'keeps a String that names the same currency' do
      expect(type.cast('MYR 12')).to eq(Money.new(1200, 'MYR'))
      expect(type.cast('RM 12')).to eq(Money.new(1200, 'MYR'))
    end

    it 'returns nil for a String Monetize cannot parse' do
      expect(type.cast('1.2.3')).to be_nil
      expect(type.cast('1-2')).to be_nil
    end
  end

  describe '#deserialize' do
    it 'reads a stored digit String as cents' do
      expect(type.deserialize('1500')).to eq(Money.new(1500, 'MYR'))
      expect(type.deserialize('0012')).to eq(Money.new(12, 'MYR'))
      expect(type.deserialize('-5')).to eq(Money.new(-5, 'MYR'))
    end

    it 'reads a stored decimal String as major units' do
      expect(type.deserialize('15.0')).to eq(Money.new(1500, 'MYR'))
    end

    it 'reads the stored hash' do
      expect(type.deserialize('{"cents":150,"currency_iso":"MYR"}')).to eq(Money.new(150, 'MYR'))
    end
  end
end

RSpec.describe 'NestedRecord monetize macro' do
  it 'raises on an option it does not support' do
    expect { Class.new(NestedRecord::Base) { monetize :fee, allow_nil: true } }
      .to raise_error(ArgumentError, /allow_nil/)
  end

  describe 'nested_accessors' do
    active_model(:FeeOwner) do
      nested_accessors from: :fees do
        monetize :gateway_fee, currency: 'MYR', default: 0
      end
    end

    it 'delegates the predicate' do
      expect(FeeOwner.new(gateway_fee: 0)).to respond_to(:gateway_fee?)
    end
  end

  describe 'inside a NestedRecord::Concern' do
    nested_concern(:FeeConcern) do
      monetize :gateway_fee, currency: 'MYR'
    end

    active_model(:ConcernOwner) do
      nested_accessors from: :fees do
        include FeeConcern
      end
    end

    it 'records and delegates monetize' do
      expect(ConcernOwner.new(gateway_fee: 150).gateway_fee).to eq(Money.new(150, 'MYR'))
    end
  end
end
