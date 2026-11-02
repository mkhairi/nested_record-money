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

    it 'makes the owner invalid when the String does not cast' do
      expect(FeeOwner.new(gateway_fee: 'abc')).not_to be_valid
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

    it 'records the cast validation too' do
      expect(ConcernOwner.new(gateway_fee: 'abc')).not_to be_valid
    end
  end

  describe 'cast validation' do
    nested_model(:FeeRecord) do
      monetize :fee, currency: 'MYR', default: 0
    end

    active_model(:FeeHolder) do
      has_one_nested :charges, class_name: 'FeeRecord'
    end

    it 'adds not_a_number when a non-blank String does not cast' do
      %w[abc 1.2.3].push('USD 12').each do |input|
        record = FeeRecord.new(fee: input)
        expect(record).not_to be_valid, "expected #{input.inspect} to be invalid"
        expect(record.errors.details[:fee]).to include(a_hash_including(error: :not_a_number, value: input))
      end
    end

    it 'accepts a blank String as nil' do
      record = FeeRecord.new(fee: '')
      expect(record).to be_valid
      expect(record.fee).to be_nil
    end

    it 'accepts a String that casts' do
      expect(FeeRecord.new(fee: '1.50')).to be_valid
    end

    it 'clears the error once a valid value is assigned' do
      record = FeeRecord.new(fee: 'abc')
      record.fee = '2.00'
      expect(record).to be_valid
    end

    it 'keeps a stored null as nil without an error' do
      record = FeeRecord.instantiate('fee' => nil)
      expect(record.fee).to be_nil
      expect(record).to be_valid
    end

    it 'applies the default for a missing key' do
      expect(FeeRecord.instantiate({}).fee).to eq(Money.new(0, 'MYR'))
    end

    it 'sees a stored null as changed against the default' do
      expect(NestedRecord::Type::Monetize.new(currency: 'MYR').changed_in_place?(nil, Money.new(0, 'MYR'))).to be(true)
    end

    it 'bubbles the error to a has_one_nested owner' do
      holder = FeeHolder.new(charges_attributes: { fee: 'abc' })
      expect(holder).not_to be_valid
      expect(holder.errors.attribute_names.map(&:to_s)).to include('charges.fee')
    end
  end
end
