module DistributionPlugin::DistributionLayoutHelper

  HeaderButtons = [
    [:start, I18n.t('distribution_plugin.lib.distribution_layout_helper.start'), proc{ @node.profile.url }, proc{ on_homepage? }],
    [:orders, I18n.t('distribution_plugin.lib.distribution_layout_helper.orders'), {:controller => :distribution_plugin_order, :action => :index}],
    #[:about, I18n.t('distribution_plugin.lib.distribution_layout_helper.about'), {:controller => :distribution_plugin_node, :action => :about}],
    #[:history, I18n.t('distribution_plugin.lib.distribution_layout_helper.history'), {:controller => :distribution_plugin_node, :action => :history}],
    [:adm, I18n.t('distribution_plugin.lib.distribution_layout_helper.administration'), {:controller => :distribution_plugin_node, :action => 'index'}, proc{ @admin_action },
      proc{ @user_node and @node.has_admin?(@user_node) }],
  ]

  def display_header_buttons
    HeaderButtons.map do |key, label, url, selected_proc, if_proc|
      next if if_proc and !instance_eval(&if_proc)

      url = instance_eval(&url) if url.is_a?(Proc)
      if key != :adm and @admin_action
        selected = false
      elsif selected_proc
        selected = instance_eval(&selected_proc)
      else
        selected = params[:controller].to_s == url[:controller].to_s
      end
      link_to label, url, :class => "menu-button #{"menu-selected" if selected}"
    end.join
  end

  def load_node
    @node = DistributionPlugin::Node.find_by_profile_id profile.id if profile
    @user_node = DistributionPlugin::Node.find_or_create current_user.person if current_user
  end

  def render_header
    return unless @node and @node.collective?
    output = render :file => 'distribution_plugin_layouts/default'
    if on_homepage?
      extend SuppliersPlugin::SuppliersProductHelper
      output += render :file => 'distribution_plugin_gadgets/sessions'
    end
    output
  end

  protected

  # FIXME: workaround to fix Profile#is_on_homepage?
  def on_homepage?
    @node.profile.is_on_homepage?(request.path, @page) or request.path == "/profile/#{@node.profile.identifier}"
  end

end
