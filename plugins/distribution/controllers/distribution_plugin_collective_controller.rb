class DistributionPluginCollectiveController < DistributionPluginMyprofileController
  no_design_blocks

  before_filter :set_admin_action, :only => [:our_products, :suppliers]

  helper DistributionPlugin::DistributionDisplayHelper

  def index
    redirect_to :controller => :distribution_plugin_session, :action => "index", :profile => params[:profile]
  end

  def parcels
  end

  def our_products
    redirect_to :controller => :distribution_plugin_product, :action => :index, :profile => profile.identifier
  end

  def suppliers
    redirect_to :controller => :distribution_plugin_manage_supplier, :action => :index, :profile => profile.identifier
  end

  def members
  end

  def about
    redirect_to :action => "index", :profile => params[:profile]
  end

  protected

  def custom_contents
    [:header, :admin_sidebar]
  end

end
