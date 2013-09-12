class NetworksPluginAdminController < AdminController

  def index
    @networks = environment.networks
    @network = NetworksPlugin::Network.new
  end

  def admin
    redirect_to :action => :index
  end

  def create
    if request.post?
      @network = NetworksPlugin::Network.new params[:network].merge(:environment => environment)
      @network.identifier = @network.name.to_slug
      if @network.save
        redirect_to :action => :index
      else
        render :action => :index
      end
    end
  end

end
