# workaround for plugins classes scope problem
require_dependency 'networks_plugin/display_helper'
NetworksPlugin::NetworksDisplayHelper = NetworksPlugin::DisplayHelper

class NetworksPluginEnterpriseController < SuppliersPluginMyprofileController

  include ControllerInheritance
  include NetworksPlugin::TranslationHelper

  before_filter :load_node, :only => [:associate, :destroy]

  helper NetworksPlugin::NetworksDisplayHelper

  def new
    super
  end

  def add
    super
  end

  def associate
    @new_supplier = SuppliersPlugin::Supplier.new_dummy :consumer => @node
    render :layout => false
  end

  def destroy
    @profile = @node
    super
  end

  protected

  def load_node
    @network = profile
    @node = NetworksPlugin::Node.find_by_id(params[:node_id]) || @network
  end

  replace_url_for self.superclass

end
