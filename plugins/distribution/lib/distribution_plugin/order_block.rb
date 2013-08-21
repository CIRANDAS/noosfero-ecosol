# workaround for plugin class scope problem
require_dependency 'distribution_plugin/display_helper'

class DistributionPlugin::OrderBlock < Block

 def self.short_description
   I18n.t('distribution_plugin.lib.order_block.orders_cycles')
 end

 def self.description
   I18n.t('distribution_plugin.lib.order_block.distribution_orders_c')
 end

 def self.available_for? profile
   node = DistributionPlugin::Node.find_or_create profile
   !node.blank? && !node.consumer?
 end

 def node
   @node ||= DistributionPlugin::Node.find_or_create owner
 end

 def default_title
   self.class.short_description
 end

 def help
   I18n.t('distribution_plugin.lib.order_block.offer_cycles_for_you_')
 end

 def content(args = {})
   n = node
   block = self

   lambda do
     consumer = current_user.is_a?(User) ? DistributionPlugin::Node.find_or_create(current_user.person) : nil
     extend DistributionPlugin::DisplayHelper
     render :file => 'blocks/distribution_plugin_order', :locals => { :block => block, :node => n, :consumer => consumer }
   end
 end

  def cacheable?
    false
  end

end

