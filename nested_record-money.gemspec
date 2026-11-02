require_relative "lib/nested_record/money/version"

Gem::Specification.new do |spec|
  spec.name          = "nested_record-money"
  spec.version       = NestedRecord::Money::VERSION
  spec.authors       = ["Mohd Khairi"]
  spec.email         = ["khairi@labs.my"]

  spec.summary       = %q{money-rails monetize for nested_record attributes}
  spec.homepage      = "https://github.com/mkhairi/nested_record-money"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*.rb", "README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "activerecord", ">= 7.2"
  spec.add_development_dependency "sqlite3", ">= 1.4"

  # nested_record >= the `extensions` branch (MacroRecorder.register, delegate_macro)
  spec.add_dependency "nested_record", ">= 1.1.2"
  spec.add_dependency "money-rails"
end
