require_dependency "#{File.dirname __FILE__}/ext/profile"
require_dependency "#{File.dirname __FILE__}/ext/product"
require_dependency "#{File.dirname __FILE__}/ext/article"

class ExchangePlugin < Noosfero::Plugin

  def self.plugin_name
    "ExchangePlugin"
  end

  def self.plugin_description
    _("A plugin that implement an exchange system inside noosfero.")
  end

  def stylesheet?
    true
  end

  def js_files
    ['exchange.js']
  end

  def control_panel_buttons
    if context.profile.enterprise?
      { :title => _('My Exchanges'), :icon => 'my-exchanges', :url => {:controller => :exchange_plugin_myprofile, :action => :index} }
    end
  end

  def sniffer_balloon_header
    nil
  end

  def sniffer_balloon_footer
    lambda { render :partial => 'sniffer_plugin_myprofile/exchange_balloon_footer' }
  end

end
