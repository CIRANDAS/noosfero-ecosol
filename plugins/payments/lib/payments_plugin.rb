class PaymentsPlugin < Noosfero::Plugin

  def stylesheet?
    false
  end

  def self.plugin_name
    _("Payments")
  end

  def self.plugin_description
    _("General order payments plugin")
  end

end
