##
# Dependencies that need to load after application init
# If don't depend on rails should be loaded on config/application.rb instead
#

unless Rails.env.development?
  middleware = Noosfero::Application.config.middleware
  middleware.insert_before ::ActionDispatch::Cookies, NoosferoHttpCaching::Middleware
end

require 'noosfero/i18n'
