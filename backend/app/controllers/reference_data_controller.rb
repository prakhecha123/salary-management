class ReferenceDataController < ApplicationController
  def show
    render json: {
      countries: OrganizationReferenceData::COUNTRIES,
      departments: OrganizationReferenceData::DEPARTMENTS,
      currencies: OrganizationReferenceData::CURRENCIES,
      statuses: Employee::STATUSES,
      country_currencies: OrganizationReferenceData::COUNTRY_CURRENCIES
    }
  end
end
