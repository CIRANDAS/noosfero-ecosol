class OrdersCyclePluginAdminItemController < OrdersPluginAdminItemController

  no_design_blocks

  # FIXME: remove me when styles move from consumers_coop plugin
  include ConsumersCoopPlugin::ControllerHelper
  include OrdersCyclePlugin::TranslationHelper

  helper OrdersCyclePlugin::TranslationHelper
  helper OrdersCyclePlugin::DisplayHelper

  protected

  extend HMVC::ClassMethods
  hmvc OrdersCyclePlugin

end
