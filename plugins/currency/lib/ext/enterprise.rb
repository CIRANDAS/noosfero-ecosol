require_dependency 'enterprise'

class Enterprise

  has_many :enterprise_currencies, :class_name => 'CurrencyPlugin::EnterpriseCurrency'
  has_many :accepted_currencies, :through => :enterprise_currencies, :source => :currency,
    :conditions => ['currency_plugin_enterprise_currencies.is_organizer <> ?', true], :order => 'id ASC'
  has_many :organized_currencies, :through => :enterprise_currencies, :source => :currency,
    :conditions => ['currency_plugin_enterprise_currencies.is_organizer = ?', true], :order => 'id ASC'
  has_many :currencies, :through => :enterprise_currencies, :source => :currency, :order => 'id ASC'

end
