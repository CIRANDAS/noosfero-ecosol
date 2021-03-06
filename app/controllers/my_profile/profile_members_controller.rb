class ProfileMembersController < MyProfileController

  no_design_blocks

  protect 'manage_memberships', :profile

  def index
    @filters = params[:filters] || {:roles => []}
    all_roles = Profile::Roles.organization_member_roles(environment.id) | Profile::Roles.organization_custom_roles(environment.id, profile.id)
    @filters[:roles] = all_roles unless @filters[:roles].present?
    @data = {}
    field = 'name'
    field = 'email' if @filters[:name] =~ /\@/

    @data[:members] = profile.members_by(field,@filters[:name]).by_role(@filters[:roles])
    session[:members_filtered] = @data[:members].map{|m|m.id} if request.post?
    @data[:roles] = all_roles

  end

  def send_mail
    session[:members_filtered] = params[:members_filtered].select{|value| value!="0"}
    if session[:members_filtered].present?
      redirect_to :controller => :profile, :action => :send_mail
    else
      session[:notice] = _("Select at least one member.")
      redirect_to :action => :index
    end
  end

  def update_roles
    @roles = params[:roles] ? environment.roles.find(params[:roles].select{|r|!r.to_i.zero?}) : []
    @roles = @roles.select{|r| r.has_kind?('Profile') }
    begin
      @person = profile.members.find(params[:person])
    rescue ActiveRecord::RecordNotFound
      @person = nil
    end

    if @person
      if@person.is_last_admin_leaving?(profile, @roles)
        redirect_to :action => :last_admin
      elsif @person.define_roles(@roles, profile)
        session[:notice] = _('Roles successfuly updated')
        redirect_to :action => 'index'
      else
        session[:notice] = _('Couldn\'t change the roles')
        redirect_to :action => 'index'
      end
    else
      redirect_to :action => 'index'
    end
  end

  def last_admin
    @roles = [Profile::Roles.admin(environment.id)]
  end

  def add_role
    @person = Person.find(params[:person])
    @role = environment.roles.find(params[:role])
    if @profile.affiliate(@person, @role)
      redirect_to :action => 'index'
    else
      @member = Person.find(params[:person])
      @roles = environment.roles.all.select{ |r| r.has_kind?('Profile') }
      render :action => 'affiliate'
    end
  end

  def remove_role
    @association = RoleAssignment.where(:id => params[:id], :target_id => profile.id)
    if @association.destroy
      session[:notice] = 'Member succefully unassociated'
    else
      session[:notice] = 'Failed to unassociate member'
    end
    render :layout => false
  end

  def change_role
    @roles = Profile::Roles.organization_member_roles(environment.id)
    @custom_roles = profile.custom_roles
    begin
      @member = profile.members.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      @member = nil
    end
    if @member
      @associations = @member.find_roles(@profile)
    else
      redirect_to :action => :index
    end
  end

  def unassociate
    member = Person.find(params[:id])
    associations = member.find_roles(profile)
    RoleAssignment.transaction do
      if associations.map(&:destroy)
        session[:notice] = _('Member succesfully unassociated')
      else
        session[:notice] = _('Failed to unassociate member')
      end
    end
    render :layout => false
  end

  def add_members
    @roles = Profile::Roles.organization_member_roles(environment.id)
  end

  def add_member
    if profile.enterprise?
      member = Person.find(params[:id])
      member.define_roles(Profile::Roles.all_roles(environment), profile)
    end
    render :layout => false
  end

  def add_admin
    @title = _('Current admins')
    @collection = :profile_admins

    if profile.community?
      member = profile.members.find_by(identifier: params[:id])
      profile.add_admin(member)
    end
    render :layout => false
  end

  def remove_admin
    @title = _('Current admins')
    @collection = :profile_admins

    if profile.community?
      member = profile.members.find_by(identifier: params[:id])
      profile.remove_admin(member)
    end
    render :layout => false
  end

  def search_user
    role = Role.find(params[:role])
    render :text => environment.people.where('LOWER(name) LIKE ? OR LOWER(identifier) LIKE ?', "%#{params['q_'+role.key]}%", "%#{params['q_'+role.key]}%").
      select { |person| !profile.members_by_role(role).include?(person) }.
      map {|person| {:id => person.id, :name => person.name} }.
      to_json
  end

  def save_associations
    error = false
    roles = Profile::Roles.organization_member_roles(environment.id)
    roles.select { |role| params['q_'+role.key] }.each do |role|
      people = [Person.find(params['q_'+role.key].split(','))].flatten
      to_remove = profile.members_by_role(role) - people
      to_add = people - profile.members_by_role(role)

      begin
        to_remove.each { |person| profile.disaffiliate(person, role) }
        to_add.each { |person| profile.affiliate(person, role) }
      rescue Exception => ex
        logger.info ex
        error = true
      end
    end

    if error
      session[:notice] = _('The members list couldn\'t be updated. Please contact the administrator.')
      redirect_to :action => 'add_members'
    else
      if profile.admins.blank? && !params[:last_admin]
        redirect_to :action => 'last_admin'
      else
        session[:notice] = _('The members list was updated.')
        redirect_to :controller => 'profile_editor'
      end
    end
  end

  def search_members
    field = 'name'
    field = 'email' if params[:filter_name] =~ /\@/

    result = profile.members_like field, params[:filter_name]
    result = result.select{|member| member.can_view_field?(current_person, "email") } if field=="email"
    render :json => result.map { |member| {:label => "#{member.name}#{member.can_view_field?(current_person, "email") ? " <#{member.email}>" : ""}", :value => member.name }}
  end

end
