# Central place for the small, slow-changing lookup data the domain relies
# on (which countries/departments/currencies exist, and how countries map to
# their default currency). Kept as plain Ruby constants rather than database
# tables: this data changes on the order of "we opened an office," not per
# request, and a real HR system would likely source it from a reference API
# — but that's outside this assessment's scope.
module OrganizationReferenceData
  COUNTRY_CURRENCIES = {
    "United States" => "USD",
    "India" => "INR",
    "United Kingdom" => "GBP",
    "Canada" => "CAD",
    "Germany" => "EUR",
    "France" => "EUR",
    "Australia" => "AUD",
    "Singapore" => "SGD"
  }.freeze

  COUNTRIES = COUNTRY_CURRENCIES.keys.freeze
  CURRENCIES = COUNTRY_CURRENCIES.values.uniq.freeze

  DEPARTMENTS = [
    "Engineering",
    "Sales",
    "Marketing",
    "Finance",
    "Human Resources",
    "Operations",
    "Customer Support",
    "Product",
    "Legal",
    "Design"
  ].freeze

  def self.default_currency_for(country)
    COUNTRY_CURRENCIES.fetch(country)
  end
end
