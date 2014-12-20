module UrlHelper

  def url_for options = {}
    return super unless options.is_a? Hash

    # @domain.owner_type check avoids an early fetch of @domain.profile
    if (!@domain or @domain.owner_type == 'Environment')
      # keep profile parameter when not using a custom domain
      # this is necessary as :profile parameter is optional in config/routes.rb
      if params[:profile].present?
        options[:profile] = params[:profile]
      end
    elsif @domain.profile and @domain.profile.identifier == options[:profile]
      # remove profile parameter for better URLs in custom domains
      options.delete :profile
    end

    super
  end

end
