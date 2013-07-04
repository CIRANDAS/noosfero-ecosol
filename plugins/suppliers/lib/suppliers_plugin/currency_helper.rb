module SuppliersPlugin::CurrencyHelper

  def self.parse_localized_number number
    return number if number.blank?
    number = number.to_s
    number.gsub(I18n.t("number.currency.format.unit"), '').gsub(I18n.t("number.currency.format.delimiter"), '').gsub(I18n.t("number.currency.format.separator"), '.').to_f
  end

  def self.parse_currency currency
    self.parse_localized_number currency
  end

  def self.number_as_currency_number number
    string = ActionController::Base.helpers.number_to_currency(number, :unit => '')
    string.gsub!(' ', '') if string
    string
  end

  def self.number_as_currency number
    ActionController::Base.helpers.number_to_currency(number)
  end

  module ClassMethods

    def has_number_with_locale field
      define_method "#{field}=" do |value|
        if value.is_a?(String)
          self[field] = SuppliersPlugin::CurrencyHelper.parse_localized_number value
        else
          self[field] = value
        end
      end

      define_method "#{field}_as_currency_number" do |*args, &block|
        number = send(field, *args, &block) rescue self[field]
        SuppliersPlugin::CurrencyHelper.number_as_currency_number number
      end
      define_method "#{field}_as_currency" do |*args, &block|
        number = send(field, *args, &block) rescue self[field]
        SuppliersPlugin::CurrencyHelper.number_as_currency number
      end
    end

    def has_currency field
      self.has_number_with_locale field
    end

  end

  module InstanceMethods

  end

end
