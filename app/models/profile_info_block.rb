class ProfileInfoBlock < Block

  def self.description
    _('Profile information block')
  end

  def help
    _('Basic information about <i>%{user}</i>: how long <i>%{user}</i> is part of <i>%{env}</i> and useful links.') % { :user => self.owner.name(), :env => self.owner.environment.name() }
  end

  def content
    block = self
    lambda do
      render :file => 'blocks/profile_info', :locals => { :block => block }
    end
  end

  def editable?
    false
  end

end
