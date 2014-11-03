class FbAppPluginMyprofileController < MyProfileController

  no_design_blocks

  before_filter :load_provider
  before_filter :load_auth

  def index
  end

  def show_login
    @status = params[:auth].delete :status
    @logged_auth = FbAppPlugin::Auth.new params[:auth]

    @logged_auth.fetch_user
    if @auth.connected?
      render 'show_login'
    end
  end

  def save_auth
    @status = params[:auth].delete :status
    if @status == FbAppPlugin::Auth::Status::Connected
      @auth.attributes = params[:auth]
      @auth.save! if @auth.changed?
    else
      @auth.destroy if @auth
      @auth = new_auth
    end

    render partial: 'settings'
  end

  def timeline_config
    @timeline_config = profile.fb_app_timeline_config
    if request.post?
      @timeline_config.update_attributes!
    end
  end

  protected

  def load_provider
    @provider = FbAppPlugin.oauth_provider_for environment
  end

  def load_auth
    @auth = FbAppPlugin::Auth.where(profile_id: user.id, provider_id: @provider.id).first
    @auth ||= new_auth
  end

  def new_auth
    FbAppPlugin::Auth.new profile_id: user.id, provider_id: @provider.id
  end

end
