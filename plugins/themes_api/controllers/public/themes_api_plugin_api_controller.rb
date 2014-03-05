class ThemesApiPluginApiController < PublicController

  def fetch_enterprises
    if user
      @enterprises = user.enterprises.select{ |e| e.admins.include? user }
      @enterprises = @enterprises.map{ |e| {:name => e.name, :identifier => e.identifier } }

      render :json => {:user => user.identifier, :enterprises => @enterprises}
    else
      render :json => {:user => nil}
    end
  end

  def create_theme
    @themes_path = ThemesApiPlugin::ThemesPath
    @profile = environment.profiles.find_by_identifier params[:profile]
    return render :json => {:error => {:code => 1, :message => 'not an admin'}} unless @profile.admins.include? user

    @base_theme = params[:base_theme]
    return render :json => {:error => {:code => 2, :message => 'could not find base theme'}} unless File.directory? "#{@themes_path}/#{@base_theme}"

    @theme_id = "profile-#{@profile.identifier}"

    @base_sass_variables = ActiveSupport::OrderedHash.new
    File.read("#{@themes_path}/#{@base_theme}/stylesheets/_variables.scss").gsub(';', '').gsub(/^\$/, '').split("\n").each do |line|
      name,value = line.split ': '
      @base_sass_variables[name] = value
    end

    @sass_variables = ActiveSupport::OrderedHash.new
    @sass_variables.update params[:sass_variables]
    @sass_variables.reverse_merge! @base_sass_variables
    @sass_variables['theme-name'] = "\"#{@theme_id}\""

    ret = system "cp -frL #{@themes_path}/#{@base_theme} #{@themes_path}/#{@theme_id}"
    return render :json => {:error => {:code => 3, :message => 'could not copy theme'}} unless ret

    ret = File.open "#{@themes_path}/#{@theme_id}/stylesheets/_variables.scss", "w" do |file|
      file << @sass_variables.map do |name, value|
        next unless name.present? and value.present?
        "$#{name}: #{value};"
      end.join("\n")
    end.present?
    return render :json => {:error => {:code => 4, :message => 'could not write variables'}} unless ret

    File.open("#{@themes_path}/#{@theme_id}/theme.yml", 'w') do |file|
      file << {
        'name' => "Seu tema personalizado",
        'layout' => "cirandas",
        'jquery_theme' => "smoothness_mod",
        'icon_theme' => ['default', 'pidgin'],
        'owner_id' => @profile.id,
        'owner_type' => @profile.type.to_s,
      }.to_yaml
    end

    @enterprise.theme = @theme_id
    @enterprise.save

    render :json => {:error => {:code => 0, :message => 'success'}}
  end


end
