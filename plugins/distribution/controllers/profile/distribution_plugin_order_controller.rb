# workaround for plugin class scope problem
require_dependency 'distribution_plugin/display_helper'
require_dependency 'suppliers_plugin/product_helper'

class DistributionPluginOrderController < OrdersPluginConsumerController

  no_design_blocks

  before_filter :load_node
  before_filter :set_admin_action, :only => [:session_edit]
  before_filter :login_required, :except => [:index]

  helper ApplicationHelper
  helper DistributionPlugin::DisplayHelper
  helper SuppliersPlugin::ProductHelper

  def index
    @year = (params[:year] || DateTime.now.year).to_s
    @sessions = @node.sessions.by_year @year
    @consumer = user
  end

  def new
    if user.nil?
      session[:notice] = t('orders_plugin.controllers.profile.consumer.please_login_first')
      redirect_to :action => :index
      return
    end
    @consumer = user
    @order = OrdersPlugin::Order.create! :consumer => @consumer
    redirect_to params.merge(:action => :edit, :id => @order.id)
    @session = DistributionPlugin::Session.find params[:session_id]
    @session_order = DistributionPlugin::SessionOrder.create! :session => @session, :order => @order
  end

  def edit
    if session_id = params[:session_id]
      @session = DistributionPlugin::Session.find_by_id session_id
      return render_not_found unless @session
      @consumer = user
    else
      return render_not_found unless @order
      @admin_edit = user and user != @consumer
      @consumer = @order.consumer
      @session = @order.session
      @consumer_orders = @session.orders.for_consumer @consumer

      render :partial => 'consumer_orders' if params[:consumer_orders]
    end

    @consumer_orders = @session.orders.for_consumer @consumer
    render :partial => 'consumer_orders' if params[:consumer_orders]
  end

  def cancel
    super
    redirect_to :action => :index, :session_id => @order.session.id
  end

  def remove
    super
    redirect_to :action => :index, :session_id => @order.session.id
  end

  def reopen
    @order = OrdersPlugin::Order.find params[:id]
    if @order.consumer == user
      raise "Cycle's orders period already ended" unless @order.session.orders?
      @order.update_attributes! :status => 'draft'
    end

    redirect_to :action => :edit, :id => @order.id
  end

  def confirm
    if @order.consumer != user and not profile.has_admin? user
      if user.nil?
        session[:notice] = t('distribution_plugin.controllers.profile.order_controller.login_first')
      else
        session[:notice] = t('distribution_plugin.controllers.profile.order_controller.you_are_not_the_owner')
      end
      redirect_to :action => :index
      return
    end

    raise "Cycle's orders period already ended" unless @order.session.orders?

    super
  end

  def admin_new
    if profile.has_admin? user
      @consumer = user
      @session = DistributionPlugin::Session.find params[:session_id]
      @order = OrdersPlugin::Order.create! :session => @session, :consumer => @consumer
      redirect_to :action => :edit, :id => @order.id, :profile => profile.identifier
    else
      redirect_to :action => :index
    end
  end

  def session_edit
    @order = OrdersPlugin::Order.find params[:id]
    if @order.consumer != user and not profile.has_admin? user
      if @user_node.nil?
        session[:notice] = t('distribution_plugin.controllers.profile.order_controller.login_first')
      else
        session[:notice] = t('distribution_plugin.controllers.profile.order_controller.you_are_not_the_owner')
      end
      redirect_to :action => :index
      return
    end

    if @order.session.orders?
      a = {}; @order.products.map{ |p| a[p.id] = p }
      b = {}; params[:order][:products].map do |key, attrs|
        p = OrdersPlugin::OrderedProduct.new attrs
        p.id = attrs[:id]
        b[p.id] = p
      end

      removed = a.values.map do |p|
        p if b[p.id].nil?
      end.compact
      changed = b.values.map do |p|
        pa = a[p.id]
        if pa and p.quantity_asked != pa.quantity_asked
          pa.quantity_asked = p.quantity_asked
          pa
        end
      end.compact

      changed.each{ |p| p.save! }
      removed.each{ |p| p.destroy }
    end

    if params[:warn_consumer]
      message = (params[:include_message] and !params[:message].blank?) ? params[:message] : nil
      DistributionPlugin::Mailer.deliver_order_change_notification @node, @order, changed, removed, message
    end

  end

  def render_delivery
    @order = OrdersPlugin::Order.find params[:id]
    @order.attributes = params[:order]
    render :partial => 'delivery', :layout => false, :locals => {:order => @order}
  end

  protected

  include DistributionPlugin::ControllerHelper

  # use superclass instead of child
  def url_for options
    options[:controller] = :distribution_plugin_order if options[:controller].to_s == 'orders_plugin_consumer'
    super options
  end

end
