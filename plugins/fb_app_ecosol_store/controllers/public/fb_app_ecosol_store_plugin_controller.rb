class FbAppEcosolStorePluginController < PublicController

  no_design_blocks

  before_filter :change_theme

  def index
    load_configs

    if params[:tabs_added]
      @page_ids = params[:tabs_added].map{ |id, value| id }
      render :action => 'tabs_added', :layout => false
    elsif @config
      if @config.profiles.present? and @config.profiles.size == 1
        @profile = @config.profiles.first
        extend CatalogHelper
        catalog_load_index

        render :action => 'catalog'
      else
        @query = if @config.profiles.present? then @config.profiles.map(&:identifier).join(' OR ') else @config.query end
      end
    else
      # render template
      render :action => 'index'
    end
  end

  def admin
    create_configs if load_configs.blank?
    @profiles = @config.profiles
    @query = @config.query
    if request.post?
      case params[:integration_type]
        when 'profiles'
          @config.profile_ids = params[:profile_ids]
        when 'query'
          @config.query = params[:keyword]
      end
      @config.save
      render :json => '', :status => :ok
    end
  end

  def uninstall
    render :text => params.to_yaml
  end

  def search
    @profiles = environment.enterprises.enabled.find_by_contents(params[:query])[:results]
    render :json => (@profiles.map do |profile|
      {:name => profile.name, :id => profile.id, :identifier => profile.identifier}
    end)
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

  def load_configs
    if params[:signed_request]
      @signed_requests = if params[:signed_request].is_a? Hash then params[:signed_request].values else params[:signed_request].to_a end
      @datas = []
      @page_ids = @signed_requests.map do |signed_request|
        @data = parse_signed_request signed_request
        @datas << @data
        @data['page']['id']
      end
    else
      @page_ids = if params[:page_id].is_a? Hash then params[:page_id].values else params[:page_id].to_a end
    end

    @configs = FbAppEcosolStorePlugin::PageConfig.where(:page_id => @page_ids)
    @config = @configs.first
    @new_request = true if @config.blank?
    @configs
  end

  def create_configs
    @page_ids.each do |page_id|
      @configs << FbAppEcosolStorePlugin::PageConfig.create!(:page_id => page_id)
    end
    @config ||= @configs.first
  end

  def change_theme
    @current_theme = 'embed_810'
    @without_pure_chat = true
  end

  def get_layout
    return if request.xhr?
    super
  end

  # backport for ruby 1.8
  def urlsafe_decode64 str
    str += '=' * (4 - str.length.modulo(4))
    Base64.decode64 str.tr("-_", "+/")
  end
  def urlsafe_encode64 str
    Base64.encode64 str.tr("+/", "-_")
  end

  def parse_signed_request signed_request
    encoded_sig, payload = signed_request.split '.'

    secret = FbAppEcosolStorePlugin.config['app']['secret'] rescue ''
    sig = urlsafe_decode64 encoded_sig
    expected_sig = OpenSSL::HMAC.digest 'sha256', secret, payload

    if expected_sig == sig
      data = urlsafe_decode64 payload
      JSON.parse(data)
    end
  end

end
