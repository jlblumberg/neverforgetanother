module ApplicationHelper
  # Options for phone country dropdown. Value is ISO (US, CA, GB) so US and Canada stay distinct.
  def phone_country_code_options
    PhoneCountries.options_for_select
  end
end
