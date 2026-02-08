# Central list of countries for the phone number form. Each entry is
# [ "Label (+N)", ISO_country_code, dial_code ]. Currently US only for text.
module PhoneCountries
  LIST = [
    ["United States (+1)", "US", "1"],
  ].freeze

  def self.dial_code_for(iso)
    LIST.find { |_label, i, _d| i == iso }&.then { |_label, _i, d| d }
  end

  def self.options_for_select
    LIST.map { |label, iso, _dial| [label, iso] }
  end
end
