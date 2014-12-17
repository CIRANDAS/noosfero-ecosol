class FbAppPluginPageTabController < FbAppPluginController

  no_design_blocks

  before_filter :change_theme
  before_filter :disable_cache

  include CatalogHelper

  helper FbAppPlugin::FbAppDisplayHelper

  def index
    return unless load_page_tabs

    if params[:tabs_added]
      @page_ids = FbAppPlugin::Profile.page_ids_from_tabs_added params[:tabs_added]
      session[:notice] = t('fb_app_plugin.views.page_tab.added_notice')
      render action: 'tabs_added', layout: false
    elsif @signed_request or @page_id
      if @page_tab.present?
        if product_id = params[:product_id]
          @product = environment.products.find product_id
          @profile = @product.profile
          @inputs = @product.inputs
          @allowed_user = false
          load_catalog

          render action: 'product'
        elsif @page_tab.profiles.present? and @page_tab.profiles.size == 1
          @profile = @page_tab.profiles.first

          load_catalog
          render action: 'catalog'
        else
          # fake profile for catalog controller
          @profile = environment.enterprise_template
          @profile.shopping_cart_settings.enabled = true

          base_query = if @page_tab.profiles.present? then @page_tab.profiles.map(&:identifier).join(' OR ') else @page_tab.query end
          params[:base_query] = base_query
          params[:scope] = 'all'

          load_catalog
          render action: 'catalog'
        end
      else
        render action: 'first_load'
      end
    else
      # render template
      render action: 'index'
    end
  end

  def search_autocomplete
    load_page_tabs
    load_search_autocomplete
    respond_to do |format|
      format.json{ render 'catalog/search_autocomplete' }
    end
  end

  def admin
    return unless load_page_tabs

    if request.put? and @page_id.present?
      create_page_tabs if @page_tab.nil?

      @page_tab.update_attributes! params[:page_tab]

      respond_to do |format|
        format.js{ render action: 'admin' }
      end
    end
  end

  def destroy
    @page_tab = FbAppPlugin::PageTab.find params[:id]
    return render_access_denied unless user.present? and (user.is_admin?(environment) or user.is_admin? @page_tab.profile)
    @page_tab.destroy
    render nothing: true
  end

  def uninstall
    render text: params.to_yaml
  end

  def enterprise_search
    scope = environment.enterprises.enabled.public
    @query = params[:query]
    @profiles = scope.limit(10).order('name ASC').
      where(['name ILIKE ? OR name ILIKE ? OR identifier LIKE ?', "#{@query}%", "% #{@query}%", "#{@query}%"])
    render partial: 'open_graph_plugin_myprofile/profile_search', locals: {profiles: @profiles}
  end

  # unfortunetely, this needs to be public
  def profile
    @profile
  end

  protected

  def default_url_options options={}
    options[:profile] = @profile.identifier if @profile
    super
  end

  def load_page_tabs
    @signed_requests = read_param params[:signed_request]
    if @signed_requests.present?
      @datas = []
      @page_ids = @signed_requests.map do |signed_request|
        @data = FbAppPlugin::Auth.parse_signed_request signed_request
        @datas << @data
        page_id = @data[:page][:id] rescue nil
        if page_id.blank?
          render_access_denied
          return false
        end
        page_id
      end
    else
      @page_ids = read_param params[:page_id]
    end

    @page_tabs = FbAppPlugin::PageTab.where page_id: @page_ids

    @signed_request = @signed_requests.first
    @page_id = @page_ids.first
    @page_tab = @page_tabs.first
    @new_request = true if @page_tab.blank?

    true
  end

  def create_page_tabs
    @page_tabs = FbAppPlugin::PageTab.create_from_page_ids @page_ids
    @page_tab ||= @page_tabs.first
  end

  def change_theme
    # move to config
    unless theme_responsive?
      @current_theme = 'ees'
      @theme_responsive = true
    end
    @without_pure_chat = true
  end
  def get_layout
    return nil if request.format == :js or request.xhr?

    return "#{Rails.root}/public/designs/themes/cirandas-responsive/layouts/cirandas-responsive"
  end

  def disable_cache
    @disable_cache_theme_navigation = true
  end

  def load_catalog options = {}
    @use_show_more = true
    catalog_load_index options
  end

  def read_param param
    if param.is_a? Hash
      param.values
    else
      Array(param).select{ |p| p.present? }
    end
  end

end
